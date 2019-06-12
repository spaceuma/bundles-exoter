#!/usr/bin/env ruby

require 'vizkit'
require 'rock/bundle'
require 'readline'

include Orocos

## Initialize orocos ##
Bundles.initialize

## Transformation for the transformer
Bundles.transformer.load_conf(Bundles.find_file('config', 'transforms_scripts.rb'))


Orocos::Process.run 'exoter_control', 'exoter_groundtruth', 'exoter_proprioceptive', 'exoter_localization' do

    # setup platform_driver
    puts "Setting up platform_driver"
    platform_driver = Orocos.name_service.get 'platform_driver'
    Orocos.conf.apply(platform_driver, ['default'], :override => true)
    platform_driver.configure
    puts "done"

    # setup read dispatcher
    puts "Setting up reading joint_dispatcher"
    read_joint_dispatcher = Orocos.name_service.get 'read_joint_dispatcher'
    Orocos.conf.apply(read_joint_dispatcher, ['reading'], :override => true)
    read_joint_dispatcher.configure
    puts "done"

    # setup the commanding dispatcher
    puts "Setting up commanding joint_dispatcher"
    command_joint_dispatcher = Orocos.name_service.get 'command_joint_dispatcher'
    Orocos.conf.apply(command_joint_dispatcher, ['commanding'], :override => true)
    command_joint_dispatcher.configure
    puts "done"

    # setup exoter locomotion_control
    puts "Setting up locomotion_control"
    locomotion_control = Orocos.name_service.get 'locomotion_control'
    Orocos.conf.apply(locomotion_control, ['default'], :override => true)
    locomotion_control.configure
    puts "done"

    # setup exoter ptu_control
    puts "Setting up ptu_control"
    ptu_control = Orocos.name_service.get 'ptu_control'
    Orocos.conf.apply(ptu_control, ['default'], :override => true)
    ptu_control.configure
    puts "done"

    # setup vicon
    puts "Setting up vicon"
    vicon = Orocos.name_service.get 'vicon'
    Orocos.conf.apply(vicon, ['default', 'exoter'], :override => true)
    vicon.configure
    puts "done"
    
    # Localization
    puts "Setting up localization_frontend"
    localization_frontend = Orocos.name_service.get 'localization_frontend'
    Orocos.conf.apply(localization_frontend, ['default', 'hamming1hzsampling12hz'], :override => true)
    localization_frontend.urdf_file = Bundles.find_file('data/odometry', 'exoter_odometry_model_complete.urdf')
    Bundles.transformer.setup(localization_frontend)
    localization_frontend.configure
    puts "done"

    # ExoTeR Threed Odometry
    puts "Setting up exoter threed_odometry"
    exoter_odometry = Orocos.name_service.get 'exoter_odometry'
    Orocos.conf.apply(exoter_odometry, ['default', 'bessel50'], :override => true)
    exoter_odometry.urdf_file = Bundles.find_file('data/odometry', 'exoter_odometry_model_complete.urdf')
    Bundles.transformer.setup(exoter_odometry)
    exoter_odometry.configure
    puts "done"

    # setup imu_stim300 
    puts "Setting up imu_stim300"
    imu_stim300 = Orocos.name_service.get 'imu_stim300'
    Orocos.conf.apply(imu_stim300, ['default', 'exoter','ESTEC','stim300_5g'], :override => true)
    imu_stim300.configure
    puts "done"

    # setup waypoint_navigation 
    puts "Setting up waypoint_navigation"
    waypoint_navigation = Orocos.name_service.get 'waypoint_navigation'
    Orocos.conf.apply(waypoint_navigation, ['default'], :override => true)
    #waypoint_navigation.apply_conf_file("config/orogen/waypoint_navigation::Task.yml",["exoter"])
    waypoint_navigation.configure
    puts "done"

    # add the trajectory generation component
    puts "Setting up the trajectory generation"
    trajectoryGen = Orocos.name_service.get 'trajectoryGen'
    Orocos.conf.apply(trajectoryGen, ['demoloop'], :override => true)
    trajectoryGen.configure
    puts "done"



    # Log all ports
    Orocos.log_all_ports

    puts "Connecting ports"
    # Connect ports: platform_driver to read_joint_dispatcher
    platform_driver.joints_readings.connect_to read_joint_dispatcher.joints_readings

    # Connect ports: read_joint_dispatcher to locomotion_control
    read_joint_dispatcher.motors_samples.connect_to locomotion_control.joints_readings

    # Connect ports: locomotion_control to command_joint_dispatcher
    locomotion_control.joints_commands.connect_to command_joint_dispatcher.joints_commands

    # Connect ports: command_joint_dispatcher to platform_driver
    command_joint_dispatcher.motors_commands.connect_to platform_driver.joints_commands

    # Connect ports: read_joint_dispatcher to ptu_control
    read_joint_dispatcher.ptu_samples.connect_to ptu_control.ptu_samples

    # Connect ports: ptu_control to command_joint_dispatcher
    ptu_control.ptu_commands_out.connect_to command_joint_dispatcher.ptu_commands

    # Connect ports: waypoint_navigation to locomotion_control
    waypoint_navigation.motion_command.connect_to locomotion_control.motion_command

    # Connect ports: trajectoryGen to waypoint_navigation
    trajectoryGen.trajectory.connect_to  waypoint_navigation.trajectory
    
    # Connect ports: ptu_control to waypoint_navigation
    vicon.pose_samples.connect_to waypoint_navigation.pose
    #puts "done"

    puts "Connecting localization ports"
    read_joint_dispatcher.joints_samples.connect_to localization_frontend.joints_samples
    #read_joint_dispatcher.ptu_samples.connect_to localization_frontend.ptu_samples
    imu_stim300.orientation_samples_out.connect_to localization_frontend.orientation_samples
    imu_stim300.compensated_sensors_out.connect_to localization_frontend.inertial_samples
    localization_frontend.joints_samples_out.connect_to exoter_odometry.joints_samples
    localization_frontend.orientation_samples_out.connect_to exoter_odometry.orientation_samples
    localization_frontend.weighting_samples_out.connect_to exoter_odometry.weighting_samples, :type => :buffer, :size => 200
    puts "done"

    # Start the tasks
    platform_driver.start
    read_joint_dispatcher.start
    command_joint_dispatcher.start
    locomotion_control.start
    ptu_control.start
    vicon.start
    localization_frontend.start
    exoter_odometry.start
    imu_stim300.start
    waypoint_navigation.start
    trajectoryGen.start

    Readline::readline("Press ENTER to generate the trajectory.")

    trajectoryGen.trigger

    #trajectory_writer = waypoint_navigation.trajectory.writer
    #trajectory = trajectory_writer.new_sample
    #waypoint1 = Types::Base::Waypoint.new
    #waypoint2 = Types::Base::Waypoint.new
    #waypoint3 = Types::Base::Waypoint.new
    #trajectory = [waypoint1, waypoint2, waypoint3]
    
    #position1 = Types::Base::Vector3d.new
    #position1 = [1.00,6.00,0.00]
    #heading1 = 0.00
    #position2 = Types::Base::Vector3d.new(5.0,6.0,0.0)
    #heading2 = -90.00
    #position3 = Types::Base::Vector3d.new(5.0,3.0,0.0)
    #heading3 = -90.00
    #trajectory = [Types::Base::Waypoint.new(:position => position1, :heading => heading1, :tol_position => 1.00, :tol_heading => 1.00)]
		  #Types::Base::Waypoint.new(:position => position2, :heading => heading2, :tol_position => 1.00, :tol_heading => 1.00),
                  #Types::Base::Waypoint.new(:position => position3, :heading => heading3, :tol_position => 1.00, :tol_heading => 1.00)]
    #trajectory_writer.write(trajectory)

    Readline::readline("Press ENTER to exit\n") do
    end

end

