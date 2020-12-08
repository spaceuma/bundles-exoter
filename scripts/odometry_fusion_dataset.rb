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
Orocos.conf.load_dir('/home/user/rock/perception/orogen/spartan/config')

# Setup tasks
Orocos::Process.run 'groundtruth', 'unit_visual_odometry', 'navigation', 'control', 'loccam', 'unit_odometry', 'spartan::Task' => 'spartan' do

    ### GROUNDTRUTH + EVALUATION
    ## SETUP VICON
    vicon = Orocos.name_service.get 'vicon'
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

    wheel_walking_control = Orocos.name_service.get 'wheel_walking_control'
    Orocos.conf.apply(wheel_walking_control, ['exoter'], :override => true)
    wheel_walking_control.configure

    locomotion_switcher = Orocos.name_service.get 'locomotion_switcher'
    Orocos.conf.apply(locomotion_switcher, ['default'], :override => true)
    locomotion_switcher.configure

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

    imu_stim300 = TaskContext.get 'imu_stim300'
    Orocos.conf.apply(imu_stim300, ['default', 'exoter', 'ESTEC', 'stim300_5g'], :override => true)
    imu_stim300.configure

    
    # Localization
    puts "Setting up localization_frontend"
    localization_frontend = Orocos.name_service.get 'localization_frontend'
    Orocos.conf.apply(localization_frontend, ['default', 'hamming1hzsampling12hz'], :override => true)
    #Orocos.conf.apply(localization_frontend, ['default', 'bessel50'], :override => true)
    localization_frontend.urdf_file = Bundles.find_file('data/odometry', 'exoter_odometry_model_complete.urdf')
    Bundles.transformer.setup(localization_frontend)
    localization_frontend.configure
    puts "done"

    # ExoTeR Odometry
    exoter_odometry = Orocos.name_service.get 'threed_odometry'
    Orocos.conf.apply(exoter_odometry, ['default', 'bessel50'], :override => true)
    exoter_odometry.urdf_file = Bundles.find_file('data/odometry', 'exoter_odometry_model_complete.urdf')
    Bundles.transformer.setup(exoter_odometry)
    exoter_odometry.configure
    
    # Connections
    Orocos.log_all_ports

    joystick.raw_command.connect_to                       motion_translator.raw_command

    motion_translator.ptu_command.connect_to              ptu_control.ptu_joints_commands
    ptu_control.ptu_commands_out.connect_to               command_joint_dispatcher.ptu_commands

    motion_translator.motion_command.connect_to           locomotion_switcher.motion_command
    motion_translator.locomotion_mode.connect_to          locomotion_switcher.locomotion_mode_override

    locomotion_switcher.kill_switch.connect_to            wheel_walking_control.kill_switch
    locomotion_switcher.reset_dep_joints.connect_to       wheel_walking_control.reset_dep_joints
    locomotion_switcher.lc_motion_command.connect_to      locomotion_control.motion_command
    
    read_joint_dispatcher.joints_samples.connect_to       locomotion_switcher.joints_readings
    read_joint_dispatcher.motors_samples.connect_to       locomotion_switcher.motors_readings

    locomotion_control.joints_commands.connect_to         locomotion_switcher.lc_joints_commands
    wheel_walking_control.joint_commands.connect_to       locomotion_switcher.ww_joints_commands

    locomotion_switcher.joints_commands.connect_to        command_joint_dispatcher.joints_commands

    command_joint_dispatcher.motors_commands.connect_to   platform_driver.joints_commands
    platform_driver.joints_readings.connect_to            read_joint_dispatcher.joints_readings
    read_joint_dispatcher.motors_samples.connect_to       locomotion_control.joints_readings
    read_joint_dispatcher.joints_samples.connect_to       wheel_walking_control.joint_readings
    read_joint_dispatcher.ptu_samples.connect_to          ptu_control.ptu_samples

    camera_firewire_loccam.frame.connect_to             camera_loccam.frame_in
    camera_loccam.left_frame.connect_to                 spartan.img_in_left
    camera_loccam.right_frame.connect_to                spartan.img_in_right
    
    read_joint_dispatcher.joints_samples.connect_to     localization_frontend.joints_samples
    imu_stim300.orientation_samples_out.connect_to      localization_frontend.orientation_samples
    imu_stim300.compensated_sensors_out.connect_to      localization_frontend.inertial_samples
    localization_frontend.joints_samples_out.connect_to exoter_odometry.joints_samples
    localization_frontend.orientation_samples_out.connect_to exoter_odometry.orientation_samples
    localization_frontend.weighting_samples_out.connect_to exoter_odometry.weighting_samples, :type => :buffer, :size => 200

    ### GROUNDTRUTH + EVALUTATION
    vicon.pose_samples.connect_to viso2_evaluation.groundtruth_pose
    spartan.vo_out.connect_to viso2_evaluation.odometry_pose
    ##############################

    # Start tasks
    platform_driver.start
    read_joint_dispatcher.start
    command_joint_dispatcher.start
    locomotion_control.start
    wheel_walking_control.start
    locomotion_switcher.start
    ptu_control.start
    motion_translator.start
    joystick.start

    
    camera_loccam.start
    camera_firewire_loccam.start
    imu_stim300.start
    localization_frontend.start
    exoter_odometry.start
    spartan.start

    ### GROUNDTRUTH + EVALUATION
    vicon.start
    viso2_evaluation.start
    ############################


    Readline::readline('Press <ENTER> to quit...');

end
