#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

options = {:v => true}

Bundles.initialize

#ENV['LANG'] = 'C'
#ENV['LC_NUMERIC'] = 'C'

Orocos::Process.run 'motion_generator::Task' => 'motion_generator' do

    motion_generator = Orocos.name_service.get 'motion_generator'
    #motion_generator.apply_conf_file("config/motion_generator::MotionCommands.yml", ["default"])
    Orocos.conf.apply(motion_generator, ['default'], :override => true)
    motion_generator.configure
    motion_generator.start

    Orocos.log_all

    Readline::readline("Press Enter to exit\n") do
    end
end
