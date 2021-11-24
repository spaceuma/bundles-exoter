#!/usr/bin/env ruby

require 'vizkit'
require 'rock/bundle'
require 'readline'

include Orocos

## Initialize orocos ##
Bundles.initialize

Orocos.run 'control' do

    # Setup read joint_dispatcher
    puts "Setting up read joint dispatcher"
    read_joint_dispatcher = Orocos.name_service.get 'read_joint_dispatcher'
    Orocos.conf.apply(read_joint_dispatcher, ['exoter_arm_reading'], :override => true)
    read_joint_dispatcher.configure
    puts "done"

    # Setup platform_driver
    puts "Setting up platform driver"
    platform_driver = Orocos.name_service.get 'platform_driver_exoter'
    Orocos.conf.apply(platform_driver, ['arm'], :override => true)
    platform_driver.configure
    puts "done"

    # Ports connection
    puts "Connecting ports"

    platform_driver.joints_readings.connect_to            read_joint_dispatcher.joints_readings

    puts "done"

    # Start
    puts "Starting platform driver"
    platform_driver.start
    puts "done"

    puts "Starting read joint dispatcher"
    read_joint_dispatcher.start
    puts "done"

    Readline::readline("Press ENTER to exit\n")
end


