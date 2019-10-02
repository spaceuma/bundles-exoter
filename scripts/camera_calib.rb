#!/usr/bin/env ruby

require 'rock/bundle'
require 'readline'

include Orocos

## Initialize orocos ##
Bundles.initialize

#Orocos::Process.run 'vicon::Task' => 'vicon1', 'vicon::Task' => 'vicon2' do
Orocos::Process.run 'vicon::Task' => ['vicon_exoter', 'vicon_cam'] do

    # Start vicon task for exoter rover
    vicon_exoter = Orocos.name_service.get 'vicon_exoter'
    Orocos.conf.apply(vicon_exoter, ['default', 'exoter'], :override => true)
    vicon_exoter.configure

    # Start vicon task for hdpr_bb2 camera
    vicon_cam = Orocos.name_service.get 'vicon_cam'
    Orocos.conf.apply(vicon_cam, ['default', 'rcenterwheel'], :override => true)
    vicon_cam.configure

    # Log all ports
    Orocos.log_all_ports

    #Start the tasks
    vicon_exoter.start
    vicon_cam.start

    Readline::readline("Press ENTER to exit\n") do
    end


end
