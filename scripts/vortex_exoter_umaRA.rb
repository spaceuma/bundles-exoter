require 'vizkit'
require 'rock/bundle'
require 'readline'

include Orocos

## Initialize orocos ##
Bundles.initialize

Orocos.run 'unit_following', 'navigation', 'control', 'simulation', 'autonomy', 'vortex::Task' => 'vortex' do

	# setup locomotion_control
    puts "Setting up locomotion_control"
    locomotion_control = Orocos.name_service.get 'locomotion_control'
    Orocos.conf.apply(locomotion_control, ['exoter'], :override => true)
    locomotion_control.configure
    puts "done"

	# setup read_joint_dispatcher
    puts "Setting up reading joint_dispatcher"
    read_joint_dispatcher = Orocos.name_service.get 'read_joint_dispatcher'
    Orocos.conf.apply(read_joint_dispatcher, ['exoter_reading'], :override => true)
    read_joint_dispatcher.configure
    puts "done"

  	# setup command_joint_dispatcher
    puts "Setting up commanding joint_dispatcher"
    command_joint_dispatcher = Orocos.name_service.get 'command_joint_dispatcher'
    Orocos.conf.apply(command_joint_dispatcher, ['exoter_commanding'], :override => true)
    command_joint_dispatcher.configure
    puts "done"

	# setup simulation_vortex
    puts "Setting up simulation_vortex"
	vortex = Orocos.name_service.get 'vortex'
  	Orocos.conf.apply(vortex, ['exoter'], :override => true)
  	vortex.configure
	puts "done"

	# setup waypoint_navigation
    puts "Setting up waypoint_navigation"
    waypoint_navigation = Orocos.name_service.get 'waypoint_navigation'
    Orocos.conf.apply(waypoint_navigation, ['default'], :override => true)
    waypoint_navigation.configure
    puts "done"

  	# setup command_arbitrer
    puts "Setting up command arbiter"
    arbiter = Orocos.name_service.get 'command_arbiter'
    Orocos.conf.apply(arbiter, ['default'], :override => true)
    arbiter.configure
    puts "done"

  	# setup path_planning
    puts "Setting up path planner"
    path_planner = Orocos.name_service.get 'path_planner'
    path_planner.keep_old_waypoints = true
    Orocos.conf.apply(path_planner, ['exoter_umaRescueArea'], :override => true)
    path_planner.configure
    puts "done"

	puts "Connecting ports"

	# command_joint_dispatcher.motors_commands.connect_to   udp.joints_commands
	# udp.joints_readings.connect_to            			  read_joint_dispatcher.joints_readings
	# locomotion_control.joints_commands.connect_to         command_joint_dispatcher.joints_commands
    # read_joint_dispatcher.motors_samples.connect_to 	  locomotion_control.joints_readings

	vortex.pose.connect_to                   			path_planner.pose
    vortex.goalWaypoint.connect_to           			path_planner.goalWaypoint
    vortex.pose.connect_to                   			waypoint_navigation.pose
   
    path_planner.trajectory.connect_to	                waypoint_navigation.trajectory
	vortex.joints_readings.connect_to					locomotion_control.joints_readings
	locomotion_control.joints_commands.connect_to		vortex.joints_commands

    waypoint_navigation.motion_command.connect_to       locomotion_control.motion_command
                

	vortex.start
	locomotion_control.start


    waypoint_navigation.start
    path_planner.start
	# read_joint_dispatcher.start
    # command_joint_dispatcher.start

	Readline::readline("Press ENTER to exit\n")

end
