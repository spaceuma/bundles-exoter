#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
require 'optparse'
require 'vizkit'

include Orocos

## Initialize orocos ##
Bundles.initialize

## Transformation for the transformer
Bundles.transformer.load_conf(Bundles.find_file('config', 'transforms_scripts_exoter.rb'))

Orocos::Process.run 'navigation', 'control', 'simulation','navcam', 'loccam', 'unit_visual_odometry', 'gps', 'imu', 'unit_bb2', 'shutter_controller','motion_planning::Task' => 'motion_planning',  'unreal::Task' => 'unreal', 'path_planning::Task' => 'path_planning', 'mission_control::Task' => 'mission_control', 'coupled_control::Task' => 'coupled_control' do

    joystick = Orocos.name_service.get 'joystick'
    # Set the joystick input
    joystick.device = "/dev/input/js0"
    # In case the dongle is not connected exit gracefully
    begin
        # Configure the joystick
        Orocos.conf.apply(joystick, ['default', 'logitech_gamepad'], :override => true)
        joystick.configure
    rescue
        # Abort the process as there is no joystick to get input from
        abort("Cannot configure the joystick, is the dongle connected to ExoTeR?")
    end


    # setup locomotion_control
    puts "Setting up locomotion_control"
    locomotion_control = Orocos.name_service.get 'locomotion_control'
    Orocos.conf.apply(locomotion_control, ['exoter'], :override => true)
    locomotion_control.configure
    puts "done"

    # setup simulation_unreal
    puts "Setting up simulation_unreal"
    unreal = Orocos.name_service.get 'unreal'
    Orocos.conf.apply(unreal, ['exoter_kinova'], :override => true)
    unreal.configure
    puts "done"

    # setup waypoint_navigation
    puts "Setting up waypoint_navigation"
    waypoint_navigation = Orocos.name_service.get 'waypoint_navigation'
    #Orocos.conf.apply(waypoint_navigation, ['default'], :override => true)
    Orocos.conf.apply(waypoint_navigation, ['exoter'], :override => true)
    waypoint_navigation.configure
    puts "done"

    # setup path_planning
    puts "Setting up path planning"
    path_planning = Orocos.name_service.get 'path_planning'
    path_planning.keep_old_waypoints = true
    Orocos.conf.apply(path_planning, ['exoter', 'marsTerrain_2cm'], :override => true)
    path_planning.configure
    puts "done"

    # setup mission_control
    puts "Setting up kinova planning"
    mission_control = Orocos.name_service.get 'mission_control'
    Orocos.conf.apply(mission_control, ['unreal_exoter_kinova'], :override => true)
    mission_control.configure
    puts "done"

    # setup coupled_control
    puts "Setting up coupled control"
    coupled_control = Orocos.name_service.get 'coupled_control'
    Orocos.conf.apply(coupled_control, ['exoter_kinova'], :override => true)
    coupled_control.configure
    puts "done"

    # setup read joint_dispatcher
    puts "Setting up read joint dispatcher"
    read_joint_dispatcher = Orocos.name_service.get 'read_joint_dispatcher'
    Orocos.conf.apply(read_joint_dispatcher, ['exoter_arm_reading'], :override => true)
    read_joint_dispatcher.configure
    puts "done"

	# setup command joint_dispatcher
    puts "Setting up command joint dispatcher"
    command_joint_dispatcher = Orocos.name_service.get 'command_joint_dispatcher'
    Orocos.conf.apply(command_joint_dispatcher, ['exoter_arm_commanding'], :override => true)
    command_joint_dispatcher.configure
    puts "done"

    locomotion_switcher = Orocos.name_service.get 'locomotion_switcher'
    Orocos.conf.apply(locomotion_switcher, ['default'], :override => true)
    locomotion_switcher.configure

    ptu_control = Orocos.name_service.get 'ptu_control'
    Orocos.conf.apply(ptu_control, ['default'], :override => true)
    ptu_control.configure

    # setup platform_driver
    puts "Setting up platform driver"
    platform_driver = Orocos.name_service.get 'platform_driver_exoter'
    Orocos.conf.apply(platform_driver, ['arm'], :override => true)
    platform_driver.configure
    puts "done"

    command_arbiter = Orocos.name_service.get 'command_arbiter'
    Orocos.conf.apply(command_arbiter, ['default'], :override => true)
    command_arbiter.configure

    motion_translator = Orocos.name_service.get 'motion_translator'
    Orocos.conf.apply(motion_translator, ['exoter'], :override => true)
    motion_translator.configure

  	# setup motion_planning
    puts "Setting up motion planning"
    motion_planning = Orocos.name_service.get 'motion_planning'
    Orocos.conf.apply(motion_planning, ['default'], :override => true)
    motion_planning.configure
    puts "done"

    imu_stim300 = TaskContext.get 'imu_stim300'
    Orocos.conf.apply(imu_stim300, ['default', 'exoter', 'Malaga', 'stim300_10g_exoter'], :override => true)
    imu_stim300.configure

    visual_odometry = TaskContext.get 'viso2'
    Orocos.conf.apply(visual_odometry, ['default','bumblebee'], :override => true)
    Bundles.transformer.setup(visual_odometry)
    #visual_odometry.configure

    viso2_with_imu = TaskContext.get 'viso2_with_imu'
    Orocos.conf.apply(viso2_with_imu, ['default'], :override => true)
    #viso2_with_imu.configure

    viso2_evaluation = TaskContext.get 'viso2_evaluation'
    Orocos.conf.apply(viso2_evaluation, ['default'], :override => true)
    #viso2_evaluation.configure

    gps = TaskContext.get 'gps'
    Orocos.conf.apply(gps, ['exoter', 'Spain', 'default'], :override => true)
    gps.configure
    
    gps_heading = TaskContext.get 'gps_heading'
    Orocos.conf.apply(gps_heading, ['default'], :override => true)
    gps_heading.configure

    puts "Starting NavCam"

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
    Orocos.conf.apply(shutter_controller_navcam, ['bb2malaga'], :override => true)
    shutter_controller_navcam.configure

    puts "Starting LocCam"

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
    Orocos.conf.apply(shutter_controller_loccam, ['bb2malaga'], :override => true)
    shutter_controller_loccam.configure

    puts "Connecting ports"

    # Ports connection

    # UNREAL outputs
    unreal.joints_readings.connect_to                                locomotion_control.joints_readings
    unreal.pose.connect_to                                           waypoint_navigation.pose
 	unreal.manipulator_readings.connect_to                           coupled_control.current_config_vector_double
    unreal.manipulator_readings.connect_to                           mission_control.joints_position_port
    unreal.pose.connect_to                                           path_planning.pose
    unreal.pose.connect_to                                           mission_control.pose_input
    unreal.goalWaypoint.connect_to                                   mission_control.goal_waypoint_input
    unreal.sample_position_port.connect_to                           mission_control.sample_position_port
    unreal.sample_orientation_port.connect_to                        mission_control.sample_orientation_port
    unreal.pose.connect_to                                           coupled_control.pose

    # Locomotion control outputs
    locomotion_control.joints_commands.connect_to                    unreal.joints_commands

    # Coupled control outputs
    coupled_control.manipulator_command_vector_double.connect_to     unreal.manipulator_commands

    # Path planning outputs
    path_planning.trajectory.connect_to                              mission_control.trajectory_port

    # Kinova planning outputs
    mission_control.num_waypoints_port.connect_to                    coupled_control.size_path 
    mission_control.modified_trajectory_port.connect_to              waypoint_navigation.trajectory
    mission_control.modified_trajectory_port.connect_to              coupled_control.trajectory
    mission_control.joints_motionplanning_matrix_port.connect_to     coupled_control.arm_profile
    mission_control.fetching_motionplanning_matrix_port.connect_to   coupled_control.final_movement_matrix_port
    mission_control.final_movement_port.connect_to                   coupled_control.kinova_final_movement_port

    viso2_evaluation.odometry_in_world_pose.connect_to               waypoint_navigation.pose
    viso2_evaluation.odometry_in_world_pose.connect_to               coupled_control.pose
    viso2_evaluation.odometry_in_world_pose.connect_to               path_planning.pose
    viso2_evaluation.odometry_in_world_pose.connect_to               mission_control.pose_input
    read_joint_dispatcher.arm_samples.connect_to                     mission_control.joints_position_port
    mission_control.goal_waypoint_output.connect_to                  path_planning.goalWaypoint

    # Waypoint navigation outputs
    waypoint_navigation.motion_command.connect_to                    coupled_control.motion_command
    waypoint_navigation.current_segment.connect_to                   coupled_control.current_segment
    waypoint_navigation.currentWaypoint.connect_to                   coupled_control.current_waypoint
    waypoint_navigation.trajectory_status.connect_to                 mission_control.trajectory_status_port

    # Coupled control outputs
    coupled_control.modified_motion_command.connect_to               locomotion_control.motion_command

    # Read joint dispatcher
    read_joint_dispatcher.joints_samples.connect_to       locomotion_switcher.joints_readings
    read_joint_dispatcher.motors_samples.connect_to       locomotion_switcher.motors_readings
    read_joint_dispatcher.motors_samples.connect_to       locomotion_control.joints_readings
    read_joint_dispatcher.arm_samples.connect_to          coupled_control.current_config
    read_joint_dispatcher.ptu_samples.connect_to          ptu_control.ptu_samples

    platform_driver.joints_readings.connect_to            read_joint_dispatcher.joints_readings

    command_arbiter.motion_command.connect_to             locomotion_switcher.motion_command
    command_arbiter.locomotion_mode.connect_to            locomotion_switcher.locomotion_mode_override

    locomotion_switcher.lc_motion_command.connect_to      locomotion_control.motion_command
    locomotion_switcher.joints_commands.connect_to        command_joint_dispatcher.joints_commands

    locomotion_control.joints_commands.connect_to         locomotion_switcher.lc_joints_commands
    locomotion_control.joints_commands.connect_to       command_joint_dispatcher.joints_commands

    motion_translator.ptu_command.connect_to              ptu_control.ptu_joints_commands
    ptu_control.ptu_commands_out.connect_to               command_joint_dispatcher.ptu_commands

    command_joint_dispatcher.motors_commands.connect_to   platform_driver.joints_commands

    joystick.raw_command.connect_to                       command_arbiter.raw_command
    coupled_control.modified_motion_command.connect_to    command_arbiter.follower_motion_command
    motion_translator.motion_command.connect_to           command_arbiter.joystick_motion_command
    motion_translator.motion_command.connect_to         locomotion_control.motion_command

    joystick.raw_command.connect_to                       motion_translator.raw_command
    joystick.raw_command.connect_to                       command_arbiter.raw_command

    # Motion planning outputs
	motion_planning.roverPath.connect_to                  waypoint_navigation.trajectory
	motion_planning.joints.connect_to                     coupled_control.manipulator_config
	motion_planning.assignment.connect_to                 coupled_control.assignment
	motion_planning.sizePath.connect_to                   coupled_control.size_path

	# Coupled control outputs
    coupled_control.modified_motion_command.connect_to    command_arbiter.follower_motion_command
    coupled_control.manipulator_command.connect_to        command_joint_dispatcher.arm_commands
	
    # Cameras and visual odometry
    camera_firewire_navcam.frame.connect_to             camera_navcam.frame_in

    camera_firewire_loccam.frame.connect_to             camera_loccam.frame_in
    camera_loccam.left_frame.connect_to                 visual_odometry.left_frame
    camera_loccam.right_frame.connect_to                visual_odometry.right_frame

    camera_loccam.left_frame.connect_to                 shutter_controller_loccam.frame
    shutter_controller_loccam.shutter_value.connect_to  camera_firewire_loccam.shutter_value

    camera_loccam.left_frame.connect_to                 stereo_loccam.left_frame
    camera_loccam.right_frame.connect_to                stereo_loccam.right_frame

    camera_navcam.left_frame.connect_to                 stereo_navcam.left_frame
    camera_navcam.right_frame.connect_to                stereo_navcam.right_frame

    camera_navcam.left_frame.connect_to                 shutter_controller_navcam.frame
    shutter_controller_navcam.shutter_value.connect_to  camera_firewire_navcam.shutter_value

    motion_translator.motion_command.connect_to         visual_odometry.motion_command
    visual_odometry.delta_pose_samples_out.connect_to   viso2_with_imu.delta_pose_samples_in
    imu_stim300.orientation_samples_out.connect_to      viso2_with_imu.pose_samples_imu

    gps_heading.pose_samples_out.connect_to             viso2_evaluation.groundtruth_pose
    viso2_with_imu.pose_samples_out.connect_to          viso2_evaluation.odometry_pose

    gps.pose_samples.connect_to                         gps_heading.gps_pose_samples
    gps.raw_data.connect_to                             gps_heading.gps_raw_data
    imu_stim300.orientation_samples_out.connect_to      gps_heading.imu_pose_samples
    motion_translator.motion_command.connect_to         gps_heading.motion_command
    puts "using gps"


    # Logging
    Orocos.log_all_configuration

    logger_gps = Orocos.name_service.get 'gps_Logger'
    logger_gps.file = "gps.log"
    logger_gps.log(gps.pose_samples)
    logger_gps.log(gps.raw_data)
    logger_gps.log(gps.time)
    logger_gps.log(gps_heading.pose_samples_out)

    logger_imu = Orocos.name_service.get 'imu_Logger'
    logger_imu.file = "imu.log"
    logger_imu.log(imu_stim300.orientation_samples_out)

    logger_loccam = Orocos.name_service.get 'loccam_Logger'
    logger_loccam.file = "loccam.log"
    logger_loccam.log(camera_firewire_loccam.frame)
    logger_loccam.log(camera_loccam.left_frame)
    logger_loccam.log(camera_loccam.right_frame)
    logger_loccam.log(stereo_loccam.disparity_frame)
    logger_loccam.log(stereo_loccam.distance_frame)

    logger_navcam = Orocos.name_service.get  'navcam_Logger'
    logger_navcam.file = "navcam.log"
    logger_navcam.log(camera_firewire_navcam.frame)
    logger_navcam.log(camera_navcam.left_frame)
    logger_navcam.log(camera_navcam.right_frame)
    logger_navcam.log(stereo_navcam.disparity_frame)
    logger_navcam.log(stereo_navcam.distance_frame)

    logger_viso2 = Orocos.name_service.get  'unit_visual_odometry_Logger'
    logger_viso2.file = "viso2.log"
    logger_viso2.log(viso2_with_imu.pose_samples_out)
    logger_viso2.log(visual_odometry.delta_pose_samples_out)
    logger_viso2.log(viso2_evaluation.diff_pose)
    logger_viso2.log(viso2_evaluation.odometry_in_world_pose)
    logger_viso2.log(viso2_evaluation.ground_truth_pose)
    logger_viso2.log(viso2_evaluation.travelled_distance)
    logger_viso2.log(viso2_evaluation.perc_error)

    # Start the components
    platform_driver.start
    read_joint_dispatcher.start
    command_joint_dispatcher.start
    locomotion_control.start
    ptu_control.start
    motion_translator.start
    joystick.start
    imu_stim300.start

	motion_planning.start
    command_arbiter.start
    locomotion_switcher.start

    #visual_odometry.start
    #viso2_with_imu.start
    #viso2_evaluation.start
    gps.start
    gps_heading.start

    camera_loccam.start
    camera_firewire_loccam.start
    stereo_loccam.start
    shutter_controller_loccam.start

    camera_navcam.start
    camera_firewire_navcam.start
    stereo_navcam.start
    shutter_controller_navcam.start

    logger_gps.start
    logger_imu.start
    logger_loccam.start
    logger_navcam.start
    logger_viso2.start    

    # Starting programs
    unreal.start

    # Waiting one second to make sure all data from Vortex has been received
    sleep(1)

    mission_control.start
    coupled_control.start
    path_planning.start
    waypoint_navigation.start
    locomotion_control.start


    Readline::readline("Press Enter to exit\n") do
    end
    ptu_control.stop
    sleep(7)


    Readline::readline("Press ENTER to exit\n")

end
