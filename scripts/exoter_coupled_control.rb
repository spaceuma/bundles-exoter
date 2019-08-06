#!/usr/bin/env ruby

require 'vizkit'
require 'rock/bundle'
require 'readline'

include Orocos

## Initialize orocos ##
Bundles.initialize


Orocos.run 'control', 'unit_vicon', 'navigation', 'motion_planning::Task' => 'motion_planning', 'coupled_control::Task' => 'coupled_control' do

    # Configure
    joystick = Orocos.name_service.get 'joystick'
    Orocos.conf.apply(joystick, ['default', 'logitech_gamepad'], :override => true)
    begin
        joystick.configure
    rescue
        abort("Cannot configure the joystick, is the dongle connected to ExoTeR?")
    end

    motion_translator = Orocos.name_service.get 'motion_translator'
    Orocos.conf.apply(motion_translator, ['exoter'], :override => true)
    motion_translator.configure


	# setup locomotion_control
    puts "Setting up locomotion_control"
    locomotion_control = Orocos.name_service.get 'locomotion_control'
    Orocos.conf.apply(locomotion_control, ['exoter'], :override => true)
    locomotion_control.configure
    puts "done"

    wheel_walking_control = Orocos.name_service.get 'wheel_walking_control'
    Orocos.conf.apply(wheel_walking_control, ['exoter'], :override => true)
    wheel_walking_control.configure

    locomotion_switcher = Orocos.name_service.get 'locomotion_switcher'
    Orocos.conf.apply(locomotion_switcher, ['default'], :override => true)
    locomotion_switcher.configure

    command_arbiter = Orocos.name_service.get 'command_arbiter'
    Orocos.conf.apply(command_arbiter, ['default'], :override => true)
    command_arbiter.configure

	# setup command joint_dispatcher
    puts "Setting up command joint dispatcher"
    command_joint_dispatcher = Orocos.name_service.get 'command_joint_dispatcher'
    Orocos.conf.apply(command_joint_dispatcher, ['exoter_arm_commanding'], :override => true)
    command_joint_dispatcher.configure
    puts "done"

    # setup platform_driver
    puts "Setting up platform driver"
    platform_driver = Orocos.name_service.get 'platform_driver_exoter'
    Orocos.conf.apply(platform_driver, ['arm'], :override => true)
    platform_driver.configure
    puts "done"

    # setup read joint_dispatcher
    puts "Setting up read joint dispatcher"
    read_joint_dispatcher = Orocos.name_service.get 'read_joint_dispatcher'
    Orocos.conf.apply(read_joint_dispatcher, ['exoter_arm_reading'], :override => true)
    read_joint_dispatcher.configure
    puts "done"

    vicon = TaskContext.get 'vicon'
    Orocos.conf.apply(vicon, ['default','exoter'], :override => true)
    vicon.configure

    ptu_control = Orocos.name_service.get 'ptu_control'
    Orocos.conf.apply(ptu_control, ['default'], :override => true)
    ptu_control.configure

	# setup waypoint_navigation
    puts "Setting up waypoint_navigation"
    waypoint_navigation = Orocos.name_service.get 'waypoint_navigation'
    Orocos.conf.apply(waypoint_navigation, ['exoter'], :override => true)
    waypoint_navigation.configure
    puts "done"

  	# setup motion_planning
    puts "Setting up motion planning"
    motion_planning = Orocos.name_service.get 'motion_planning'
    Orocos.conf.apply(motion_planning, ['default'], :override => true)
    motion_planning.configure
    puts "done"

  	# setup coupled_control
    puts "Setting up coupled control"
    coupled_control = Orocos.name_service.get 'coupled_control'
    Orocos.conf.apply(coupled_control, ['exoter'], :override => true)
    coupled_control.configure
    puts "done"

	puts "Connecting ports"

    # Connect
    joystick.raw_command.connect_to                       motion_translator.raw_command
    joystick.raw_command.connect_to                       command_arbiter.raw_command

    motion_translator.ptu_command.connect_to              ptu_control.ptu_joints_commands
    motion_translator.motion_command.connect_to           command_arbiter.joystick_motion_command

    command_arbiter.motion_command.connect_to             locomotion_switcher.motion_command
    command_arbiter.locomotion_mode.connect_to            locomotion_switcher.locomotion_mode_override

    ptu_control.ptu_commands_out.connect_to               command_joint_dispatcher.ptu_commands

    locomotion_switcher.kill_switch.connect_to            wheel_walking_control.kill_switch
    locomotion_switcher.reset_dep_joints.connect_to       wheel_walking_control.reset_dep_joints
    locomotion_switcher.lc_motion_command.connect_to      locomotion_control.motion_command
    locomotion_switcher.joints_commands.connect_to        command_joint_dispatcher.joints_commands

    locomotion_control.joints_commands.connect_to         locomotion_switcher.lc_joints_commands

    wheel_walking_control.joint_commands.connect_to       locomotion_switcher.ww_joints_commands

    read_joint_dispatcher.joints_samples.connect_to       locomotion_switcher.joints_readings
    read_joint_dispatcher.motors_samples.connect_to       locomotion_switcher.motors_readings
    read_joint_dispatcher.motors_samples.connect_to       locomotion_control.joints_readings
    read_joint_dispatcher.arm_samples.connect_to          coupled_control.currentConfig
    read_joint_dispatcher.joints_samples.connect_to       wheel_walking_control.joint_readings
    read_joint_dispatcher.ptu_samples.connect_to          ptu_control.ptu_samples

    command_joint_dispatcher.motors_commands.connect_to   platform_driver.joints_commands

    platform_driver.joints_readings.connect_to            read_joint_dispatcher.joints_readings

    vicon.pose_samples.connect_to                         waypoint_navigation.pose

	# Motion planning outputs
	motion_planning.roverPath.connect_to                  waypoint_navigation.trajectory
	motion_planning.joints.connect_to                     coupled_control.manipulatorConfig
	motion_planning.assignment.connect_to                 coupled_control.assignment
	motion_planning.sizePath.connect_to                   coupled_control.sizePath

	# Coupled control outputs
    coupled_control.modifiedMotionCommand.connect_to      command_arbiter.follower_motion_command
    coupled_control.manipulatorCommand.connect_to         command_joint_dispatcher.arm_commands
	
	# Waypoint navigation outputs
	waypoint_navigation.motion_command.connect_to         coupled_control.motionCommand
	waypoint_navigation.current_segment.connect_to        coupled_control.currentSegment

    # Start
	motion_planning.start
    command_arbiter.start
	coupled_control.start
    platform_driver.start
    read_joint_dispatcher.start
    command_joint_dispatcher.start
    locomotion_control.start
    wheel_walking_control.start
    locomotion_switcher.start
    ptu_control.start
    motion_translator.start
    joystick.start
    waypoint_navigation.start
    vicon.start

	Readline::readline("Press ENTER to exit\n")
end


