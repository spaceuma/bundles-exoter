#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

options = {:v => true}

Bundles.initialize

Bundles.transformer.load_conf(Bundles.find_file('config', 'transforms_scripts_exoter.rb'))

Orocos::Process.run 'imu', 'vicon::Task' => 'vicon' do


    imu_stim300 = TaskContext.get 'imu_stim300'
    Orocos.conf.apply(imu_stim300, ['default', 'exoter', 'ESTEC', 'stim300_5g'], :override => true)
    imu_stim300.configure

    vicon = Orocos.name_service.get 'vicon'
    Orocos.conf.apply(vicon, ['default','exoter_new'], :override => true)
    vicon.configure


    Orocos.log_all


   imu_stim300.start
   vicon.start

   Readline::readline("Press Enter to exit\n") do
   end

end
