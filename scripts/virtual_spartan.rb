#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
require 'vizkit'
include Orocos

options = {:v => true}

Bundles.initialize
tfse_file = Bundles.find_file('config', 'transforms_scripts_exoter.rb')
Bundles.transformer.load_conf(tfse_file)

# open log file 
log = Orocos::Log::Replay.open('~/rock/bundles/exoter/logs/20191101-1513/loccam.0.log', 
                               '~/rock/bundles/exoter/logs/20191101-1513/motion_generator.0.log', 
                               '~/rock/bundles/exoter/logs/20191101-1513/imu.0.log',
                               '~/rock/bundles/exoter/logs/20191101-1513/vicon.0.log')

log.use_sample_time = true

Orocos::Process.run 'imu', 'viso2_with_imu::Task' => 'viso2_with_imu', 'stereo_vo::SpartanVO' => 'spartan', 'viso2_evaluation::Task' => ['viso2_evaluation','viso2_evaluation_imu'] do

    # CONFIGURE TASKS
    viso2_evaluation = Orocos.name_service.get 'viso2_evaluation'
    Orocos.conf.apply(viso2_evaluation, ['default'], :override => true)
    viso2_evaluation.configure

    viso2_evaluation_imu = Orocos.name_service.get 'viso2_evaluation_imu'
    Orocos.conf.apply(viso2_evaluation_imu, ['default'], :override => true)
    viso2_evaluation_imu.configure
    
    viso2_with_imu = TaskContext.get 'viso2_with_imu'
    Orocos.conf.apply(viso2_with_imu, ['default'], :override => true)
    viso2_with_imu.configure

    spartan = Orocos.name_service.get 'spartan'
    spartan.configure

    imu_stim300 = TaskContext.get 'imu_stim300'
    Orocos.conf.apply(imu_stim300, ['default', 'exoter', 'ESTEC', 'stim300_5g'], :override => true    )
    imu_stim300.configure

    Orocos.log_all_ports
    
    
    # SET UP CONNECTIONS BETWEEN TASKS
    log.camera_loccam.left_frame.connect_to             spartan.img_in_left 
    log.camera_loccam.right_frame.connect_to            spartan.img_in_right

    log.motion_generator.motion_command.connect_to      spartan.motion_command
    
    log.vicon.pose_samples.connect_to                   viso2_evaluation.groundtruth_pose
    spartan.vo_out.connect_to                           viso2_evaluation.odometry_pose
    
    spartan.delta_vo_out.connect_to                     viso2_with_imu.delta_pose_samples_in
    imu_stim300.orientation_samples_out.connect_to      viso2_with_imu.pose_samples_imu
    
    viso2_with_imu.pose_samples_out.connect_to          viso2_evaluation_imu.odometry_pose
    log.vicon.pose_samples.connect_to                   viso2_evaluation_imu.groundtruth_pose
    

    # START TASKS
    spartan.start
    viso2_evaluation.start
    viso2_evaluation_imu.start
    imu_stim300.start
    viso2_with_imu.start


    # START LOG REPLAY
    log.run(true,1)

end
