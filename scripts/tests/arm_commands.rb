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

    # CONVENTION: Positive speed = joint right-hand-rule rotation around the local z-axis,
    # where the local z-axis is pointing "into" the joint, i.e. looking back toward the joint
    # along the next kinematic link means we are looking at the positive end of the z-axis.

    #joint_elements[18] = Types.base.JointState.Position(0)
    joint_elements[19] = Types.base.JointState.Position(1.5708)
 #   joint_elements[20] = Types.base.JointState.Position(1.3)
  #  joint_elements[21] = Types.base.JointState.Position(-1.5708)
   # joint_elements[22] = Types.base.JointState.Position(-1.5708)
    # initial config: 0 -1.5708 2.21 -1.5708 0
    # pos for vo: 1 1.5708 0 0 0

    # The following can be useful in cases where a specific configuration is required and
    # for some reason the arm's internal logic tries to reach the desired position
    # the long way around, which can cause delays or lead to the arm crashing into
    # other rover parts.
    # joint_elements[JOINT_ID] = Types.base.JointState.Speed(SPEED)



    command = Types.base.commands.Joints.new(
                time: Time.at(0),
                names: joint_names,
                elements: joint_elements)
    
    writer.write(command)

    Readline::readline("Press Enter to exit\n") do
    end
end
