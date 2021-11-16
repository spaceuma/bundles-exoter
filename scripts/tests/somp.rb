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

    arm_state_writer = mpc_somp.arm_joints.writer

    arm_joint_names = ["ARM_JOINT_1", "ARM_JOINT_2", "ARM_JOINT_3", "ARM_JOINT_4", "ARM_JOINT_5"]

    init_element = Types.base.JointState.new(
                        position: Float::NAN,
                        speed: Float::NAN,
                        effort: Float::NAN,
                        acceleration: Float::NAN)

    arm_joint_elements = Array.new(5, init_element)

    arm_joint_elements[0] = Types.base.JointState.Position(0.5708)
    arm_joint_elements[1] = Types.base.JointState.Position(-3.14159265)
    arm_joint_elements[2] = Types.base.JointState.Position(2.21)
    arm_joint_elements[3] = Types.base.JointState.Position(1.5708)
    arm_joint_elements[4] = Types.base.JointState.Position(0.0)

    arm_joint_elements[0].speed = 0.0
    arm_joint_elements[1].speed = 0.0
    arm_joint_elements[2].speed = 0.0
    arm_joint_elements[3].speed = 0.0
    arm_joint_elements[4].speed = 0.0

    arm_reading = Types.base.commands.Joints.new(
                time: Time.at(0),
                names: arm_joint_names,
                elements: arm_joint_elements)

    arm_state_writer.write(arm_reading)

    goal_writer = mpc_somp.goal_ee_pose.writer
    goal = Types::Base::Samples::RigidBodyState.new()

    goal.position[0] = 3.5
    goal.position[1] = 6.0
    goal.position[2] = 0.1
    goal.orientation.x = 0.2706019
    goal.orientation.y = 0.6532799
    goal.orientation.z = 0.2706019
    goal.orientation.w = 0.6532799

    goal_writer.write(goal)

    pose_writer = mpc_somp.robot_pose.writer
    pose = Types::Base::Samples::RigidBodyState.new()

    pose.position[0] = 1.5
    pose.position[1] = 6.0
    pose.orientation.x = 0
    pose.orientation.y = 0
    pose.orientation.z = 0.247404
    pose.orientation.w = 0.9689124

    pose_writer.write(pose)

    Readline::readline("Press ENTER to send a new goal\n")

    goal.position[0] = 3.7
    goal.position[1] = 6.0
    goal.position[2] = 0.1
    goal.orientation.x = 0.2706019
    goal.orientation.y = 0.6532799
    goal.orientation.z = 0.2706019
    goal.orientation.w = 0.6532799

    goal_writer.write(goal)

    Readline::readline("Press ENTER to exit\n")
end


