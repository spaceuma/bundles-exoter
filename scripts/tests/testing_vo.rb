#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
require 'optparse'
#require 'vizkit'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

## Transformation for the transformer
Bundles.transformer.load_conf(Bundles.find_file('config', 'transforms_scripts_exoter.rb'))

# Execute the task
Orocos::Process.run 'control', 'navcam', 'loccam', 'navigation', 'unit_visual_odometry', 'gps', 'imu', 'gyro', 'unit_bb2', 'shutter_controller' do
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

    # Configure the control packages
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

    imu_stim300 = TaskContext.get 'imu_stim300'
    Orocos.conf.apply(imu_stim300, ['default', 'exoter', 'Malaga', 'stim300_10g_exoter'], :override => true)
    imu_stim300.configure

    #gyro = TaskContext.get 'dsp1760'
    #Orocos.conf.apply(gyro, ['exoter'], :override => true)
    #gyro.configure

    visual_odometry = TaskContext.get 'viso2'
    Orocos.conf.apply(visual_odometry, ['default','bumblebee'], :override => true)
    Bundles.transformer.setup(visual_odometry)
    visual_odometry.configure

    viso2_with_imu = TaskContext.get 'viso2_with_imu'
    Orocos.conf.apply(viso2_with_imu, ['default'], :override => true)
    viso2_with_imu.configure

    viso2_evaluation = TaskContext.get 'viso2_evaluation'
    Orocos.conf.apply(viso2_evaluation, ['default'], :override => true)
    viso2_evaluation.configure

    gps = TaskContext.get 'gps'
    Orocos.conf.apply(gps, ['exoter', 'Spain', 'Malaga'], :override => true)
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

    # Configure the connections between the components
    joystick.raw_command.connect_to                     motion_translator.raw_command

    motion_translator.ptu_command.connect_to            ptu_control.ptu_joints_commands
    motion_translator.motion_command.connect_to         locomotion_control.motion_command
    locomotion_control.joints_commands.connect_to       command_joint_dispatcher.joints_commands
    ptu_control.ptu_commands_out.connect_to             command_joint_dispatcher.ptu_commands

    command_joint_dispatcher.motors_commands.connect_to platform_driver.joints_commands
    platform_driver.joints_readings.connect_to          read_joint_dispatcher.joints_readings
    read_joint_dispatcher.motors_samples.connect_to     locomotion_control.joints_readings
    read_joint_dispatcher.ptu_samples.connect_to        ptu_control.ptu_samples

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

    gps.pose_samples.connect_to                         viso2_evaluation.groundtruth_pose
    viso2_with_imu.pose_samples_out.connect_to          viso2_evaluation.odometry_pose

    gps.pose_samples.connect_to                         gps_heading.gps_pose_samples
    gps.raw_data.connect_to                             gps_heading.gps_raw_data
    imu_stim300.orientation_samples_out.connect_to      gps_heading.imu_pose_samples
    #gyro.orientation_samples.connect_to                 gps_heading.gyro_pose_samples
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

    # Start the components
    platform_driver.start
    read_joint_dispatcher.start
    command_joint_dispatcher.start
    locomotion_control.start
    ptu_control.start
    motion_translator.start
    joystick.start
    imu_stim300.start

    visual_odometry.start
    viso2_with_imu.start
    viso2_evaluation.start
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

    Readline::readline("Press Enter to exit\n") do
    end
    ptu_control.stop
    sleep(7)
end
