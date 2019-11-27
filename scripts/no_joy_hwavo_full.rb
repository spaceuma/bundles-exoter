#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
require 'vizkit'
include Orocos

options = {:v => true}

Bundles.initialize

Bundles.transformer.load_conf(Bundles.find_file('config', 'transforms_scripts_exoter.rb'))

# open log file (only uncomment one)
#log = Orocos::Log::Replay.open('~/rock/bundles/exoter/logs/20190919-1255/loccam.0.log', 
#                               '~/rock/bundles/exoter/logs/20190919-1255/control.0.log', 
#                               '~/rock/bundles/exoter/logs/20190919-1255/imu.0.log',
#                               '~/rock/bundles/exoter/logs/20190919-1255/unit_visual_odometry.0.log')
log = Orocos::Log::Replay.open('~/rock/bundles/exoter/logs/20191021-1357/loccam.0.log', 
                               '~/rock/bundles/exoter/logs/20191021-1357/control.0.log', 
                               '~/rock/bundles/exoter/logs/20191021-1357/imu.0.log',
                               '~/rock/bundles/exoter/logs/20191021-1357/vicon.0.log')

log.use_sample_time = true

Orocos::Process.run 'unit_visual_odometry' do

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


    Orocos.log_all_ports
    

    log.camera_loccam.left_frame.connect_to                 visual_odometry.left_frame
    log.camera_loccam.right_frame.connect_to                visual_odometry.right_frame

    # connect the motion command to viso2 to use the if not moving then no vo logic
    #log.motion_translator.motion_command.connect_to        visual_odometry.motion_command

    visual_odometry.delta_pose_samples_out.connect_to       viso2_with_imu.delta_pose_samples_in
    log.imu_stim300.orientation_samples_out.connect_to      viso2_with_imu.pose_samples_imu
    
    # connect the GT from either the viso log or the vicon log 
    #log.viso2_evaluation.ground_truth_pose.connect_to      viso2_evaluation.groundtruth_pose
    log.vicon.pose_samples.connect_to                       viso2_evaluation.groundtruth_pose

    # connect or not the IMU to the viso evaluation
    viso2_with_imu.pose_samples_out.connect_to              viso2_evaluation.odometry_pose
    #visual_odometry.pose_samples_out.connect_to          viso2_evaluation.odometry_pose


    visual_odometry.start
    viso2_with_imu.start
    viso2_evaluation.start
    
    log.run(true,1)

end
