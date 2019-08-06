#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'control' do

    # Configure
    platform_driver = Orocos.name_service.get 'platform_driver_exoter'
    Orocos.conf.apply(platform_driver, ['arm'], :override => true)
    platform_driver.configure


    # Log
    #Orocos.log_all_ports
    #platform_driver.log_all_ports
    #pancam_panorama.log_all_ports

    # Connect

    # Start
    platform_driver.start

    Readline::readline("Press Enter to exit\n") do
    end
end
