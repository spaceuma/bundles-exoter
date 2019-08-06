#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'motion_planning::Task' => 'motion_planning' do

    # Configure
    motion_planning = Orocos.name_service.get 'motion_planning'
    Orocos.conf.apply(motion_planning, ['default'], :override => true)
    motion_planning.configure


    # Log
    #Orocos.log_all_ports
    #platform_driver.log_all_ports
    #pancam_panorama.log_all_ports

    # Connect

    # Start
    motion_planning.start

    Readline::readline("Press Enter to exit\n") do
    end
end
