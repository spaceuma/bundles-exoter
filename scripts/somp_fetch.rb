#!/usr/bin/env ruby

require 'vizkit'
require 'rock/bundle'
require 'readline'

include Orocos

## Initialize orocos ##
Bundles.initialize

## Transformation for the transformer
Bundles.transformer.load_conf(Bundles.find_file('config', 'transforms_scripts_exoter.rb'))

Orocos.run 'control', 'navcam', 'loccam', 'unit_visual_odometry', 'imu', 'unit_bb2', 'shutter_controller', 'mpc_somp::Task' => 'mpc_somp', 'vicon::Task' => 'vicon', 'mission_control::Task' => 'mission_control' do

    # Setup mpc_somp
    puts "Setting up mpc_somp"
    mpc_somp = Orocos.name_service.get 'mpc_somp'
    Orocos.conf.apply(mpc_somp, ['exoter_ack'], :override => true)
    mpc_somp.configure
    puts "done"
    
    # setup mission_control
    puts "Setting up mission control"
    mission_control = Orocos.name_service.get 'mission_control'
    Orocos.conf.apply(mission_control, ['exoter_rover'], :override => true)
    mission_control.firsthand_arm_movement = true
    mission_control.somp_integrated = true
    mission_control.configure
    puts "done"

    # Setup read joint_dispatcher
    puts "Setting up read joint dispatcher"
    read_joint_dispatcher = Orocos.name_service.get 'read_joint_dispatcher'
    Orocos.conf.apply(read_joint_dispatcher, ['exoter_arm_reading'], :override => true)
    read_joint_dispatcher.configure
    puts "done"

	# Setup command joint_dispatcher
    puts "Setting up command joint dispatcher"
    command_joint_dispatcher = Orocos.name_service.get 'command_joint_dispatcher'
    Orocos.conf.apply(command_joint_dispatcher, ['exoter_arm_commanding'], :override => true)
    command_joint_dispatcher.configure
    puts "done"

    # Setup ptu_control
    puts "Setting up ptu control"
    ptu_control = Orocos.name_service.get 'ptu_control'
    Orocos.conf.apply(ptu_control, ['default'], :override => true)
    ptu_control.configure
    puts "done"

    # Setup platform_driver
    puts "Setting up platform driver"
    platform_driver = Orocos.name_service.get 'platform_driver_exoter'
    Orocos.conf.apply(platform_driver, ['arm'], :override => true)
    platform_driver.configure
    puts "done"

    # Setup imu
    puts "Setting up imu"
    imu_stim300 = TaskContext.get 'imu_stim300'
    Orocos.conf.apply(imu_stim300, ['default', 'exoter', 'ESTEC', 'stim300_10g_exoter'], :override => true)
    imu_stim300.configure
    puts "done"

    # Setup visual odometry
    puts "Setting up viso2"
    visual_odometry = TaskContext.get 'viso2'
    Orocos.conf.apply(visual_odometry, ['default','bumblebee'], :override => true)
    Bundles.transformer.setup(visual_odometry)
    visual_odometry.configure

    puts "Setting up viso2"
    viso2_with_imu = TaskContext.get 'viso2_with_imu'
    Orocos.conf.apply(viso2_with_imu, ['default'], :override => true)
    viso2_with_imu.configure

    puts "Setting up viso2"
    viso2_evaluation = TaskContext.get 'viso2_evaluation'
    Orocos.conf.apply(viso2_evaluation, ['default'], :override => true)
    viso2_evaluation.configure
    puts "done"

    # Setup vicon
    puts "Setting up vicon"
    vicon = Orocos.name_service.get 'vicon'
    Orocos.conf.apply(vicon, ['default','exoter'], :override => true)
    vicon.configure
    puts "done"

    # Setup NavCam
    puts "Setting up NavCam"

    camera_firewire_navcam = TaskContext.get 'camera_firewire_navcam'
    Orocos.conf.apply(camera_firewire_navcam, ['exoter_bb2'], :override => true)
    camera_firewire_navcam.configure

    camera_navcam = TaskContext.get 'camera_navcam'
    Orocos.conf.apply(camera_navcam, ['exoter_bb2'], :override => true)
    camera_navcam.configure

    stereo_navcam = TaskContext.get 'stereo_navcam'
    Orocos.conf.apply(stereo_navcam, ['exoter_bb2'], :override => true)
    stereo_navcam.configure

    shutter_controller_navcam = TaskContext.get 'shutter_controller_navcam'
    Orocos.conf.apply(shutter_controller_navcam, ['bb2malaga_lab'], :override => true)
    shutter_controller_navcam.configure
    puts "done"

    # Setup LocCam
    puts "Setting up LocCam"

    camera_firewire_loccam = TaskContext.get 'camera_firewire_loccam'
    Orocos.conf.apply(camera_firewire_loccam, ['exoter_bb2_b'], :override => true)
    camera_firewire_loccam.configure

    camera_loccam = TaskContext.get 'camera_loccam'
    Orocos.conf.apply(camera_loccam, ['hdpr_bb2'], :override => true)
    camera_loccam.configure

    stereo_loccam = TaskContext.get 'stereo_bb2'
    Orocos.conf.apply(stereo_loccam, ['hdpr_bb2'], :override => true)
    stereo_loccam.configure

    shutter_controller_loccam = TaskContext.get 'shutter_controller_bb2'
    Orocos.conf.apply(shutter_controller_loccam, ['bb2malaga_lab'], :override => true)
    shutter_controller_loccam.configure
    puts "done"

    # Ports connection
    puts "Connecting ports"

    vicon.pose_samples.connect_to                         mpc_somp.robot_pose
    vicon.pose_samples.connect_to                         mission_control.pose_input
    #viso2_evaluation.odometry_in_world_pose.connect_to    mpc_somp.robot_pose
    read_joint_dispatcher.arm_samples.connect_to          mpc_somp.arm_joints
    read_joint_dispatcher.arm_samples.connect_to          mission_control.joints_position_port
    read_joint_dispatcher.motors_samples.connect_to       mpc_somp.base_joints

    read_joint_dispatcher.ptu_samples.connect_to          ptu_control.ptu_samples

    mpc_somp.arm_joints_command.connect_to                command_joint_dispatcher.arm_commands
    mpc_somp.base_joints_command.connect_to               command_joint_dispatcher.joints_commands

    mpc_somp.control_state.connect_to                     mission_control.somp_state
    mission_control.sample_world_pose.connect_to          mpc_somp.goal_ee_pose

    ptu_control.ptu_commands_out.connect_to               command_joint_dispatcher.ptu_commands

    platform_driver.joints_readings.connect_to            read_joint_dispatcher.joints_readings

    command_joint_dispatcher.motors_commands.connect_to   platform_driver.joints_commands

    camera_firewire_navcam.frame.connect_to               camera_navcam.frame_in

    camera_firewire_loccam.frame.connect_to               camera_loccam.frame_in
    camera_loccam.left_frame.connect_to                   visual_odometry.left_frame
    camera_loccam.right_frame.connect_to                  visual_odometry.right_frame

    camera_loccam.left_frame.connect_to                   shutter_controller_loccam.frame
    shutter_controller_loccam.shutter_value.connect_to    camera_firewire_loccam.shutter_value

    camera_loccam.left_frame.connect_to                   stereo_loccam.left_frame
    camera_loccam.right_frame.connect_to                  stereo_loccam.right_frame

    camera_navcam.left_frame.connect_to                   stereo_navcam.left_frame
    camera_navcam.right_frame.connect_to                  stereo_navcam.right_frame

    camera_navcam.left_frame.connect_to                   shutter_controller_navcam.frame
    shutter_controller_navcam.shutter_value.connect_to    camera_firewire_navcam.shutter_value

    mpc_somp.indirect_motion_command.connect_to           visual_odometry.motion_command
    visual_odometry.delta_pose_samples_out.connect_to     viso2_with_imu.delta_pose_samples_in
    imu_stim300.orientation_samples_out.connect_to        viso2_with_imu.pose_samples_imu

    vicon.pose_samples.connect_to                         viso2_evaluation.groundtruth_pose
    viso2_with_imu.pose_samples_out.connect_to            viso2_evaluation.odometry_pose

    # Logging
    mpc_somp.log_all_ports
    read_joint_dispatcher.log_all_ports
    vicon.log_all_ports
    viso2_evaluation.log_all_ports

    # Start
    camera_loccam.start
    camera_firewire_loccam.start
    stereo_loccam.start
    shutter_controller_loccam.start

    camera_navcam.start
    camera_firewire_navcam.start
    stereo_navcam.start
    shutter_controller_navcam.start

    platform_driver.start
    command_joint_dispatcher.start
    read_joint_dispatcher.start
    ptu_control.start

    vicon.start
    imu_stim300.start
    visual_odometry.start
    viso2_with_imu.start
    viso2_evaluation.start

    mpc_somp.start

    mission_control.start

    # Send 30 degrees to NavCam PTU
    writer = platform_driver.joints_commands.writer

    joint_names = ["WHEEL_DRIVE_FL", "WHEEL_DRIVE_FR", "WHEEL_DRIVE_CL", "WHEEL_DRIVE_CR", "WHEEL_DRIVE_BL", "WHEEL_DRIVE_BR", "WHEEL_STEER_FL", "WHEEL_STEER_FR", "WHEEL_STEER_BL", "WHEEL_STEER_BR", "WHEEL_WALK_FL", "WHEEL_WALK_FR", "WHEEL_WALK_CL", "WHEEL_WALK_CR", "WHEEL_WALK_BL", "WHEEL_WALK_BR", "MAST_PAN", "MAST_TILT", "ARM_JOINT_1", "ARM_JOINT_2", "ARM_JOINT_3", "ARM_JOINT_4", "ARM_JOINT_5"]

    init_element = Types.base.JointState.new(
                        position: Float::NAN,
                        speed: Float::NAN,
                        effort: Float::NAN,
                        acceleration: Float::NAN)

    joint_elements = Array.new(23, init_element)

    joint_elements[17] = Types.base.JointState.Position(0.5236)

    command = Types.base.commands.Joints.new(
                time: Time.at(0),
                names: joint_names,
                elements: joint_elements)

    writer.write(command)

    # Dummy writing the input robot pose port
    pose_writer = mpc_somp.robot_pose.writer
    pose = Types.base.samples.RigidBodyState.new()

    pose.position[0] = 1.5
    pose.position[1] = 6.0
    pose.orientation.x = 0
    pose.orientation.y = 0
    pose.orientation.z = 0.0
    pose.orientation.w = 1.0

    #pose_writer.write(pose)

    # Starting the script
    #Readline::readline("Press ENTER to send the goal\n")

    # Dummy writing the input end effector goal port
    #goal_writer = mpc_somp.goal_ee_pose.writer
    #goal = Types.base.samples.RigidBodyState.new()

    #goal.position[0] = 4.0
    #goal.position[1] = 5.7
    #goal.position[2] = 0.1
    #goal.orientation.x = 0.0
    #goal.orientation.y = 0.0
    #goal.orientation.z = 0.3801884
    #goal.orientation.w = 0.9249091

    #goal_writer.write(goal)

    #while mpc_somp.state != :FOLLOWING
    #    sleep 1
    #end

    #while mpc_somp.state != :TARGET_REACHED
    #    sleep 1
    #end

    #Readline::readline("Press ENTER to send a second goal\n")

    #goal.position[0] = 5.5
    #goal.position[1] = 6.0
    #goal.position[2] = 0.1
    #goal.orientation.x = 0.2706019
    #goal.orientation.y = 0.6532799
    #goal.orientation.z = 0.2706019
    #goal.orientation.w = 0.6532799

    #goal_writer.write(goal)

    #while mpc_somp.state != :FOLLOWING
    #    sleep 1
    #end

    #while mpc_somp.state != :TARGET_REACHED
    #    sleep 1
    #end

    Readline::readline("Press ENTER to exit\n")
end


