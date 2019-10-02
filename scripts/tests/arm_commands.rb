#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'control' do
    platform_driver = Orocos.name_service.get 'platform_driver_exoter'
    Orocos.conf.apply(platform_driver, ['arm'], :override => true)
    platform_driver.configure

    writer = platform_driver.joints_commands.writer

    joint_names = ["WHEEL_DRIVE_FL", "WHEEL_DRIVE_FR", "WHEEL_DRIVE_CL", "WHEEL_DRIVE_CR", "WHEEL_DRIVE_BL", "WHEEL_DRIVE_BR", "WHEEL_STEER_FL", "WHEEL_STEER_FR", "WHEEL_STEER_BL", "WHEEL_STEER_BR", "WHEEL_WALK_FL", "WHEEL_WALK_FR", "WHEEL_WALK_CL", "WHEEL_WALK_CR", "WHEEL_WALK_BL", "WHEEL_WALK_BR", "MAST_PAN", "MAST_TILT", "ARM_JOINT_1", "ARM_JOINT_2", "ARM_JOINT_3", "ARM_JOINT_4", "ARM_JOINT_5"]

    init_element = Types.base.JointState.new(
                        position: Float::NAN,
                        speed: Float::NAN,
                        effort: Float::NAN,
                        acceleration: Float::NAN)

    joint_elements = Array.new(23, init_element)

    # Start
    platform_driver.start

    joint_elements[18] = Types.base.JointState.Position(1)
    joint_elements[19] = Types.base.JointState.Position(1.5708)  #-1.5708
    joint_elements[20] = Types.base.JointState.Position(0)      #2.21
    joint_elements[21] = Types.base.JointState.Position(0)  #-1.5708
    joint_elements[22] = Types.base.JointState.Position(0)
    # pos for visodom: 1 1.5708 0 0 0

    command = Types.base.commands.Joints.new(
                time: Time.at(0),
                names: joint_names,
                elements: joint_elements)
    
    writer.write(command)

    Readline::readline("Press Enter to exit\n") do
    end
end
