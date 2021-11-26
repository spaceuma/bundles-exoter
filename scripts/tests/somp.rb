#!/usr/bin/env ruby

require 'vizkit'
require 'rock/bundle'
require 'readline'

include Orocos

## Initialize orocos ##
Bundles.initialize


Orocos.run 'mpc_somp::Task' => 'mpc_somp' do

    # Setup mpc_somp
    puts "Setting up mpc_somp..."
    mpc_somp = Orocos.name_service.get 'mpc_somp'
    Orocos.conf.apply(mpc_somp, ['exoter_ack'], :override => true)
    mpc_somp.configure
    puts "done"

    # Start
    mpc_somp.start

    # Dummy writing the input arm joints readings port
    arm_state_writer = mpc_somp.arm_joints.writer

    arm_joint_names = ["ARM_JOINT_1", "ARM_JOINT_2", "ARM_JOINT_3", "ARM_JOINT_4", "ARM_JOINT_5"]

    init_element = Types.base.JointState.new(
                        position: 0,
                        speed: 0,
                        effort: 0,
                        acceleration: 0)

    arm_joint_elements = Array.new(5, init_element)

    arm_joint_elements[0] = Types.base.JointState.Position(1.0)
    arm_joint_elements[1] = Types.base.JointState.Position(1.5708)
    arm_joint_elements[2] = Types.base.JointState.Position(-2.21)
    arm_joint_elements[3] = Types.base.JointState.Position(0.0)
    arm_joint_elements[4] = Types.base.JointState.Position(0.0)

    arm_joint_elements[0].speed = 0
    arm_joint_elements[1].speed = 0
    arm_joint_elements[2].speed = 0
    arm_joint_elements[3].speed = 0
    arm_joint_elements[4].speed = 0

    arm_reading = Types.base.commands.Joints.new(
                time: Time.at(0),
                names: arm_joint_names,
                elements: arm_joint_elements)

    arm_state_writer.write(arm_reading)

    # Dummy writing the input base joints readings port
    base_state_writer = mpc_somp.base_joints.writer

    motors_samples_names = ["WHEEL_DRIVE_FL", "WHEEL_DRIVE_FR", "WHEEL_DRIVE_CL", "WHEEL_DRIVE_CR", "WHEEL_DRIVE_BL", "WHEEL_DRIVE_BR", "WHEEL_STEER_FL", "WHEEL_STEER_FR", "WHEEL_STEER_BL", "WHEEL_STEER_BR", "WHEEL_WALK_FL", "WHEEL_WALK_FR", "WHEEL_WALK_CL", "WHEEL_WALK_CR", "WHEEL_WALK_BL", "WHEEL_WALK_BR"]

    motors_samples_elements = Array.new(16, init_element)

    motors_samples_reading = Types.base.commands.Joints.new(
                time: Time.at(0),
                names: motors_samples_names,
                elements: motors_samples_elements)

    base_state_writer.write(motors_samples_reading)

    # Dummy writing the input robot pose port
    pose_writer = mpc_somp.robot_pose.writer
    pose = Types.base.samples.RigidBodyState.new()

    pose.position[0] = 5.0
    pose.position[1] = 6.4
    pose.orientation.x = 0.0
    pose.orientation.y = 0.0
    pose.orientation.z = -0.7068252
    pose.orientation.w = 0.7073883

    pose_writer.write(pose)

    # Dummy writing the input end effector goal port
    goal_writer = mpc_somp.goal_ee_pose.writer
    goal = goal_writer.new_sample

    goal.push(4.7)
    goal.push(5.22)
    goal.push(0.1)
    goal.push(0.0)
    goal.push(1.5708)
    goal.push(0.78)

    goal_writer.write(goal)

    Readline::readline("Press ENTER to exit\n")
end


