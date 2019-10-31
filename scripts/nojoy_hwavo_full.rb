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

Orocos::Process.run 'unit_visual_odometry', 'stereo_vo::SpartanVO' => 'spartan' do


    viso2_evaluation = TaskContext.get 'viso2_evaluation'
    Orocos.conf.apply(viso2_evaluation, ['default'], :override => true)
    viso2_evaluation.configure

    spartan = Orocos.name_service.get 'spartan'
    spartan.configure

    Orocos.log_all_ports
    

    log.camera_loccam.left_frame.connect_to             spartan.img_in_left 
    log.camera_loccam.right_frame.connect_to            spartan.img_in_right

    # connect the GT from either the viso log or the vicon log 
    #log.viso2_evaluation.ground_truth_pose.connect_to   viso2_evaluation.groundtruth_pose
    log.vicon.pose_samples.connect_to                   viso2_evaluation.groundtruth_pose

    # connect or not the IMU to the viso evaluation
    spartan.vo_out.connect_to                            viso2_evaluation.odometry_pose
    #visual_odometry.pose_samples_out.connect_to         viso2_evaluation.odometry_pose


    spartan.start
    viso2_evaluation.start
    
    log.run(true,1)

    Readline::readline('Press <ENTER> to quit...');

end
