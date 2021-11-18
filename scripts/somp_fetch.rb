#!/usr/bin/env ruby

require 'vizkit'
require 'rock/bundle'
require 'readline'

include Orocos

## Initialize orocos ##
Bundles.initialize


Orocos.run 'control', 'mpc_somp::Task' => 'mpc_somp', 'vicon::Task' => 'vicon' do

    # Setup mpc_somp
    puts "Setting up mpc_somp"
    mpc_somp = Orocos.name_service.get 'mpc_somp'
    Orocos.conf.apply(mpc_somp, ['exoter_ack'], :override => true)
    mpc_somp.configure
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

    # Setup vicon
    puts "Setting up vicon"
    vicon = Orocos.name_service.get 'vicon'
    Orocos.conf.apply(vicon, ['default','exoter'], :override => true)
    vicon.configure
    puts "done"

    # Ports connection
    puts "Connecting ports"

    vicon.pose_samples.connect_to                         mpc_somp.robot_pose
    read_joint_dispatcher.arm_samples.connect_to          mpc_somp.arm_joints
    read_joint_dispatcher.motors_samples.connect_to       mpc_somp.base_joints

    read_joint_dispatcher.ptu_samples.connect_to          ptu_control.ptu_samples

    mpc_somp.arm_joints_command.connect_to                command_joint_dispatcher.arm_commands
    mpc_somp.base_joints_commands.connect_to              command_joint_dispatcher.joints_commands
    ptu_control.ptu_commands_out.connect_to               command_joint_dispatcher.ptu_commands

    platform_driver.joints_readings.connect_to            read_joint_dispatcher.joints_readings

    command_joint_dispatcher.motors_commands.connect_to   platform_driver.joints_commands

    # Logging
    mpc_somp.log_all_ports
    read_joint_dispatcher.log_all_ports
    vicon.log_all_ports

    # Start
    mpc_somp.start
    platform_driver.start
    command_joint_dispatcher.start
    read_joint_dispatcher.start
    ptu_control.start
    vicon.start

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


    # Starting the script
    Readline::readline("Press ENTER to send the first goal\n")

    # Dummy writing the input end effector goal port
    goal_writer = mpc_somp.goal_ee_pose.writer
    goal = Types.base.samples.RigidBodyState.new()

    goal.position[0] = 3.5
    goal.position[1] = 6.0
    goal.position[2] = 0.1
    goal.orientation.x = 0.2706019
    goal.orientation.y = 0.6532799
    goal.orientation.z = 0.2706019
    goal.orientation.w = 0.6532799

    goal_writer.write(goal)

    while mpc_somp.state != :FOLLOWING
        sleep 1
    end

    while mpc_somp.state != :TARGET_REACHED
        sleep 1
    end

    Readline::readline("Press ENTER to send a second goal\n")

    goal.position[0] = 5.5
    goal.position[1] = 6.0
    goal.position[2] = 0.1
    goal.orientation.x = 0.2706019
    goal.orientation.y = 0.6532799
    goal.orientation.z = 0.2706019
    goal.orientation.w = 0.6532799

    goal_writer.write(goal)

    while mpc_somp.state != :FOLLOWING
        sleep 1
    end

    while mpc_somp.state != :TARGET_REACHED
        sleep 1
    end

    Readline::readline("Press ENTER to exit\n")
end


