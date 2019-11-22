#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

options = {:v => true}

Bundles.initialize

Bundles.transformer.load_conf(Bundles.find_file('config', 'transforms_scripts_exoter.rb'))

Orocos::Process.run 'control', 'loccam', 'imu', 'navigation', 'vicon::Task' => 'vicon', 'motion_generator::Task' => 'motion_generator' do

    ## Change the name in the Orocos.conf.apply file to select the desired trajectory in ~/rock/bundles/rover/config/orogen/motion_generator::Task.yml
    motion_generator = Orocos.name_service.get 'motion_generator'
    Orocos.conf.apply(motion_generator, ['default'], :override => true)
    motion_generator.configure

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

    imu_stim300 = TaskContext.get 'imu_stim300'
    Orocos.conf.apply(imu_stim300, ['default', 'exoter', 'ESTEC', 'stim300_5g'], :override => true)
    imu_stim300.configure

    vicon = Orocos.name_service.get 'vicon'
    Orocos.conf.apply(vicon, ['default','exoter'], :override => true)
    vicon.configure

    camera_firewire_loccam = TaskContext.get 'camera_firewire_loccam'
    Orocos.conf.apply(camera_firewire_loccam, ['exoter_bb2_b','auto_exposure'], :override => true)
    camera_firewire_loccam.configure

    camera_loccam = TaskContext.get 'camera_loccam'
    Orocos.conf.apply(camera_loccam, ['hdpr_bb2'], :override => true)
    camera_loccam.configure

    Orocos.log_all


    #motion_generator.ptu_command.connect_to            ptu_control.ptu_joints_commands
    ptu_control.ptu_commands_out.connect_to             command_joint_dispatcher.ptu_commands

    motion_generator.motion_command.connect_to          locomotion_switcher.motion_command
    motion_generator.locomotion_mode.connect_to         locomotion_switcher.locomotion_mode_override

    locomotion_switcher.kill_switch.connect_to          wheel_walking_control.kill_switch
    locomotion_switcher.reset_dep_joints.connect_to     wheel_walking_control.reset_dep_joints
    locomotion_switcher.lc_motion_command.connect_to    locomotion_control.motion_command
    read_joint_dispatcher.joints_samples.connect_to     locomotion_switcher.joints_readings
    read_joint_dispatcher.motors_samples.connect_to     locomotion_switcher.motors_readings
    read_joint_dispatcher.joints_samples.connect_to     wheel_walking_control.joint_readings

    locomotion_control.joints_commands.connect_to       locomotion_switcher.lc_joints_commands
    wheel_walking_control.joint_commands.connect_to     locomotion_switcher.ww_joints_commands

    locomotion_switcher.joints_commands.connect_to      command_joint_dispatcher.joints_commands

    command_joint_dispatcher.motors_commands.connect_to platform_driver.joints_commands
    platform_driver.joints_readings.connect_to          read_joint_dispatcher.joints_readings
    read_joint_dispatcher.motors_samples.connect_to     locomotion_control.joints_readings
    read_joint_dispatcher.ptu_samples.connect_to        ptu_control.ptu_samples

    camera_firewire_loccam.frame.connect_to             camera_loccam.frame_in

    platform_driver.start
    read_joint_dispatcher.start
    command_joint_dispatcher.start
    locomotion_control.start
    wheel_walking_control.start
    locomotion_switcher.start
    ptu_control.start
    imu_stim300.start

    camera_firewire_loccam.start
    camera_loccam.start

    vicon.start

    motion_generator.start

    Readline::readline("Press Enter to exit\n") do
    end

end
