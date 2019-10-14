#!/usr/bin/env ruby

require 'readline'

require 'rock/bundle'
require 'orocos'
require 'vizkit'
include Orocos

# Initialize orocos
#Orocos.initialize

options = {:v => true}

# Init & configure Bundles
Bundles.initialize
tfse_file = Bundles.find_file('config', 'transforms_scripts_exoter.rb')
Bundles.transformer.load_conf(tfse_file)

# Setup tasks
Orocos::Process.run 'loccam', 'stereo_vo::SpartanVO' => 'spartan' do
    #'stereo_vo::Mirage' => 'mirage',

    #mirage = Orocos.name_service.get 'mirage'

    # Configure firewire
    camera_firewire_loccam = TaskContext.get 'camera_firewire_loccam'
    Orocos.conf.apply(camera_firewire_loccam, ['exoter_bb2_b', 'auto_exposure'], :override => true)
    camera_firewire_loccam.configure

    # Configure loccam
    camera_loccam = TaskContext.get 'camera_loccam'
    Orocos.conf.apply(camera_loccam, ['hdpr_bb2'], :override => true)
    camera_loccam.configure

    camera_loccam.log_all_ports

    spartan = Orocos.name_service.get 'spartan'

    # Connections first
    #spartan.img_in_left.connect_to mirage.img_out_left
    #spartan.img_in_right.connect_to mirage.img_out_right

    camera_firewire_loccam.frame.connect_to camera_loccam.frame_in
    camera_loccam.left_frame.connect_to spartan.img_in_left
    camera_loccam.right_frame.connect_to spartan.img_in_right

    #mirage.configure
    #mirage.start

    camera_loccam.start
    camera_firewire_loccam.start

    # Start tasks
    spartan.configure
    spartan.start

    Readline::readline('Press <ENTER> to quit...');

end
