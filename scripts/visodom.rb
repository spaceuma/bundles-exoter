#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

options = {:v => true}

Bundles.initialize

Bundles.transformer.load_conf(Bundles.find_file('config', 'transforms_scripts_exoter.rb'))

Orocos::Process.run 'control', 'loccam', 'imu', 'unit_vicon', 'navigation', 'unit_visual_odometry' do
    joystick = Orocos.name_service.get 'joystick'
    joystick.device = "/dev/input/js0"
    # In case the dongle is not connected exit gracefully
    begin
        Orocos.conf.apply(joystick, ['default'], :override => true)
        joystick.configure
        rescue
        abort("Cannot configure the joystick, is the dongle connected to ExoTeR?")
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

    platform_driver = Orocos.name_service.get 'platform_driver'
    Orocos.conf.apply(platform_driver, ['exoter'], :override => true)
    platform_driver.configure

    read_joint_dispatcher = Orocos.name_service.get 'read_joint_dispatcher'
    Orocos.conf.apply(read_joint_dispatcher, ['exoter_reading'], :override => true)
    read_joint_dispatcher.configure

    ptu_control = Orocos.name_service.get 'ptu_control'
    Orocos.conf.apply(ptu_control, ['default'], :override => true)
    ptu_control.configure

    imu_stim300 = TaskContext.get 'imu_stim300'
    Orocos.conf.apply(imu_stim300, ['default', 'exoter', 'ESTEC', 'stim300_5g'], :override => true)
    imu_stim300.configure

    visual_odometry = TaskContext.get 'viso2'
    Orocos.conf.apply(visual_odometry, ['default','bumblebee'], :override => true)
    Bundles.transformer.setup(visual_odometry)
    visual_odometry.configure

    viso2_with_imu = TaskContext.get 'viso2_with_imu'
    Orocos.conf.apply(visual_odometry, ['default'], :override => true)
    viso2_with_imu.configure

    viso2_evaluation = TaskContext.get 'viso2_evaluation'
    Orocos.conf.apply(viso2_evaluation, ['default'], :override => true)
    viso2_evaluation.configure

    vicon = TaskContext.get 'vicon'
    Orocos.conf.apply(vicon, ['default','exoter'], :override => true)
    vicon.configure

    camera_firewire_loccam = TaskContext.get 'camera_firewire_loccam'
    Orocos.conf.apply(camera_firewire_loccam, ['exoter_bb2_b'], :override => true)
    camera_firewire_loccam.configure

    camera_loccam = TaskContext.get 'camera_loccam'
    Orocos.conf.apply(camera_loccam, ['hdpr_bb2'], :override => true)
    camera_loccam.configure

    camera_loccam.log_all_ports
    visual_odometry.log_all_ports
    viso2_evaluation.log_all_ports
    viso2_with_imu.log_all_ports

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

    camera_loccam.left_frame.connect_to                 visual_odometry.left_frame
    camera_loccam.right_frame.connect_to                visual_odometry.right_frame

    motion_translator.motion_command.connect_to         visual_odometry.motion_command
    visual_odometry.delta_pose_samples_out.connect_to   viso2_with_imu.delta_pose_samples_in
    imu_stim300.orientation_samples_out.connect_to      viso2_with_imu.pose_samples_imu
#    imu_stim300.orientation_samples_out.connect_to      viso2_with_imu.pose_samples_imu_extra

    vicon.pose_samples.connect_to                       viso2_evaluation.groundtruth_pose
    viso2_with_imu.pose_samples_out.connect_to          viso2_evaluation.odometry_pose

    platform_driver.start
    read_joint_dispatcher.start
    command_joint_dispatcher.start
    locomotion_control.start
    ptu_control.start
    motion_translator.start
    joystick.start
    imu_stim300.start

    camera_loccam.start
    camera_firewire_loccam.start

    visual_odometry.start
    viso2_with_imu.start
    viso2_evaluation.start
    vicon.start

    Readline::readline("Press Enter to exit\n") do
    end
end
