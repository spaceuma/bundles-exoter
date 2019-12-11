#!/usr/bin/env ruby

require 'readline'

require 'rock/bundle'
require 'orocos'
require 'vizkit'
include Orocos

options = {:v => true}

# Init & configure Bundles
Bundles.initialize
tfse_file = Bundles.find_file('config', 'transforms_scripts_exoter.rb')
Bundles.transformer.load_conf(tfse_file)
Orocos.conf.load_dir('/home/marta/rock/perception/orogen/spartan/config')

# Setup tasks
Orocos::Process.run 'unit_vicon', 'unit_visual_odometry', 'navigation', 'control', 'loccam', 'spartan::Task' => 'spartan' do

    ### GROUNDTRUTH + EVALUATION
    ## SETUP VICON
    vicon = TaskContext.get 'vicon'
    Orocos.conf.apply(vicon, ['default', 'exoter'], :override => true)
    vicon.configure

    ## SETUP VISO2_EVAL
    viso2_evaluation = TaskContext.get 'viso2_evaluation'
    Orocos.conf.apply(viso2_evaluation, ['default'], :override => true)
    viso2_evaluation.configure
    ##############################

    # Joystick connection
    joystick = Orocos.name_service.get 'joystick'
    joystick.device = "/dev/input/js0"
    # Check for existence -> if not exit
    begin
        Orocos.conf.apply(joystick, ['default'], :override => true)
        joystick.configure
    rescue
        abort('Cannot configure the joystick, is the dongle connected to ExoTeR?')
    end

    motion_translator = Orocos.name_service.get 'motion_translator'
    Orocos.conf.apply(motion_translator, ['exoter'], :override => true)
    motion_translator.configure

    locomotion_control = Orocos.name_service.get 'locomotion_control'
    Orocos.conf.apply(locomotion_control, ['exoter'], :override => true)
    locomotion_control.configure

    command_joint_dispatcher = Orocos.name_service.get 'command_joint_dispatcher'
    Orocos.conf.apply(command_joint_dispatcher, ['exoter_commanding'], :override => true)
    command_joint_dispatcher.configure

    platform_driver = Orocos.name_service.get 'platform_driver_exoter'
    Orocos.conf.apply(platform_driver, ['arm'], :override => true)
    platform_driver.configure

    read_joint_dispatcher = Orocos.name_service.get 'read_joint_dispatcher'
    Orocos.conf.apply(read_joint_dispatcher, ['exoter_reading'], :override => true)
    read_joint_dispatcher.configure

    ptu_control = Orocos.name_service.get 'ptu_control'
    Orocos.conf.apply(ptu_control, ['default'], :override => true)
    ptu_control.configure
    # Configure firewire
    camera_firewire_loccam = TaskContext.get 'camera_firewire_loccam'
    Orocos.conf.apply(camera_firewire_loccam, ['exoter_bb2_b', 'auto_exposure'], :override => true)
    camera_firewire_loccam.configure

    # Configure loccam
    camera_loccam = TaskContext.get 'camera_loccam'
    Orocos.conf.apply(camera_loccam, ['hdpr_bb2'], :override => true)
    camera_loccam.configure


    spartan = Orocos.name_service.get 'spartan'
    Orocos.conf.apply(spartan, ['default'], :override => true)
    Orocos.transformer.setup(spartan)
    spartan.configure

    # Connections
    Orocos.log_all_ports

    joystick.raw_command.connect_to                     motion_translator.raw_command
    motion_translator.ptu_command.connect_to            ptu_control.ptu_joints_commands
    motion_translator.motion_command.connect_to         locomotion_control.motion_command
    locomotion_control.joints_commands.connect_to       command_joint_dispatcher.joints_commands
    ptu_control.ptu_commands_out.connect_to             command_joint_dispatcher.ptu_commands
    command_joint_dispatcher.motors_commands.connect_to platform_driver.joints_commands
    platform_driver.joints_readings.connect_to          read_joint_dispatcher.joints_readings
    read_joint_dispatcher.motors_samples.connect_to     locomotion_control.joints_readings
    read_joint_dispatcher.ptu_samples.connect_to        ptu_control.ptu_samples
    camera_firewire_loccam.frame.connect_to             camera_loccam.frame_in
    camera_loccam.left_frame.connect_to                 spartan.img_in_left
    camera_loccam.right_frame.connect_to                spartan.img_in_right

    ### GROUNDTRUTH + EVALUTATION
    vicon.pose_samples.connect_to viso2_evaluation.groundtruth_pose
    spartan.vo_out.connect_to viso2_evaluation.odometry_pose
    ##############################

    # Start tasks

    platform_driver.start
    read_joint_dispatcher.start
    command_joint_dispatcher.start
    locomotion_control.start
    ptu_control.start
    motion_translator.start
    joystick.start
    camera_loccam.start
    camera_firewire_loccam.start

    ### GROUNDTRUTH + EVALUATION
    vicon.start
    viso2_evaluation.start
    ############################

    spartan.start

    Readline::readline('Press <ENTER> to quit...');

end
