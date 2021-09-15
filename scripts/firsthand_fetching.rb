#!/USR/bin/env ruby

require 'vizkit'
require 'rock/bundle'
require 'readline'
require 'orocos'
require 'optparse'

include Orocos

## Initialize orocos ##
Bundles.initialize

## Transformation for the transformer
Bundles.transformer.load_conf(Bundles.find_file('config', 'transforms_scripts_exoter.rb'))

Orocos::Process.run 'navigation', 'autonomy', 'control', 'simulation','loccam',
  'unit_bb2', 'shutter_controller',
  'mission_control::Task' => 'mission_control', 
  'coupled_control::Task' => 'coupled_control' do

    # setup mission_control
    puts "Setting up kinova planning"
    mission_control = Orocos.name_service.get 'mission_control'
    Orocos.conf.apply(mission_control, ['exoter_rover'], :override => true)
    mission_control.firsthand_arm_movement = true
    mission_control.configure
    puts "done"

    ptu_control = Orocos.name_service.get 'ptu_control'
    Orocos.conf.apply(ptu_control, ['default'], :override => true)
    ptu_control.configure

    # setup coupled_control
    puts "Setting up coupled control"
    coupled_control = Orocos.name_service.get 'coupled_control'
    Orocos.conf.apply(coupled_control, ['exoter_rover'], :override => true)
    coupled_control.firsthand_arm_movement = true
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

    # setup locomotion_control
    puts "Setting up locomotion_control"
    locomotion_control = Orocos.name_service.get 'locomotion_control'
    Orocos.conf.apply(locomotion_control, ['exoter'], :override => true)
    locomotion_control.configure
    puts "done"

    # setup platform_driver
    puts "Setting up platform driver"
    platform_driver = Orocos.name_service.get 'platform_driver_exoter'
    Orocos.conf.apply(platform_driver, ['arm'], :override => true)
    platform_driver.configure
    puts "done"

    writer = platform_driver.joints_commands.writer

    joint_names = ["WHEEL_DRIVE_FL", "WHEEL_DRIVE_FR", "WHEEL_DRIVE_CL", "WHEEL_DRIVE_CR", "WHEEL_DRIVE_BL", "WHEEL_DRIVE_BR", "WHEEL_STEER_FL", "WHEEL_STEER_FR", "WHEEL_STEER_BL", "WHEEL_STEER_BR", "WHEEL_WALK_FL", "WHEEL_WALK_FR", "WHEEL_WALK_CL", "WHEEL_WALK_CR", "WHEEL_WALK_BL", "WHEEL_WALK_BR", "MAST_PAN", "MAST_TILT", "ARM_JOINT_1", "ARM_JOINT_2", "ARM_JOINT_3", "ARM_JOINT_4", "ARM_JOINT_5"]

    init_element = Types.base.JointState.new(
                        position: Float::NAN,
                        speed: Float::NAN,
                        effort: Float::NAN,
                        acceleration: Float::NAN)

    joint_elements = Array.new(23, init_element)

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

    # Path planning outputs

    # Kinova planning outputs
    #mission_control.num_waypoints_port.connect_to                    coupled_control.size_path 
    #mission_control.modified_trajectory_port.connect_to              coupled_control.trajectory
    #mission_control.joints_motionplanning_matrix_port.connect_to     coupled_control.arm_profile
    mission_control.fetching_motionplanning_matrix_port.connect_to   coupled_control.final_movement_matrix_port
    mission_control.final_movement_port.connect_to                   coupled_control.kinova_final_movement_port
    mission_control.start_movement.connect_to                        coupled_control.start_movement

    read_joint_dispatcher.arm_samples.connect_to                     mission_control.joints_position_port

    ptu_control.ptu_commands_out.connect_to             command_joint_dispatcher.ptu_commands
    read_joint_dispatcher.ptu_samples.connect_to        ptu_control.ptu_samples
    coupled_control.modified_motion_command.connect_to               locomotion_control.motion_command
    read_joint_dispatcher.motors_samples.connect_to       locomotion_control.joints_readings
    locomotion_control.joints_commands.connect_to       command_joint_dispatcher.joints_commands
    # Waypoint navigation outputs

    # Coupled control outputs
    coupled_control.movement_finished.connect_to               mission_control.movement_finished

    # Read joint dispatcher
    read_joint_dispatcher.arm_samples.connect_to          coupled_control.current_config

    platform_driver.joints_readings.connect_to            read_joint_dispatcher.joints_readings


    command_joint_dispatcher.motors_commands.connect_to   platform_driver.joints_commands


	# Coupled control outputs
    coupled_control.manipulator_command.connect_to        command_joint_dispatcher.arm_commands
	
    # Cameras and visual odometry

    camera_firewire_loccam.frame.connect_to             camera_loccam.frame_in

    camera_loccam.left_frame.connect_to                 shutter_controller_loccam.frame
    shutter_controller_loccam.shutter_value.connect_to  camera_firewire_loccam.shutter_value

    camera_loccam.left_frame.connect_to                 stereo_loccam.left_frame
    camera_loccam.right_frame.connect_to                stereo_loccam.right_frame



    # Logging
    Orocos.log_all_configuration


    logger_loccam = Orocos.name_service.get 'loccam_Logger'
    logger_loccam.file = "loccam.log"
    logger_loccam.log(camera_firewire_loccam.frame)
    logger_loccam.log(camera_loccam.left_frame)
    logger_loccam.log(camera_loccam.right_frame)
    logger_loccam.log(stereo_loccam.disparity_frame)
    logger_loccam.log(stereo_loccam.distance_frame)

    mission_control.log_all_ports
    platform_driver.log_all_ports

    # Start the components
    sleep(1)
    platform_driver.start
    sleep(1)
    read_joint_dispatcher.start
    command_joint_dispatcher.start
    locomotion_control.start
    ptu_control.start
    
    camera_loccam.start
    camera_firewire_loccam.start
    stereo_loccam.start
    shutter_controller_loccam.start

    coupled_control.start

    logger_loccam.start

    # Waiting one second to make sure all data from Vortex has been received
    sleep(1)

    mission_control.start

    Readline::readline("Press ENTER to exit\n")

end

