require 'vizkit'
require 'rock/bundle'
require 'readline'

include Orocos

## Initialize orocos ##
Bundles.initialize


Orocos.run 'navigation', 'control', 'simulation', 'vortex::Task' => 'vortex', 'motion_planning::Task' => 'motion_planning', 'coupled_control::Task' => 'coupled_control' do

	# setup locomotion_control
    puts "Setting up locomotion_control"
    locomotion_control = Orocos.name_service.get 'locomotion_control'
    Orocos.conf.apply(locomotion_control, ['exoter'], :override => true)
    locomotion_control.configure
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

  	# setup motion_planning
    puts "Setting up motion planning"
    motion_planning = Orocos.name_service.get 'motion_planning'
    Orocos.conf.apply(motion_planning, ['default'], :override => true)
    motion_planning.configure
    puts "done"

  	# setup coupled_control
    puts "Setting up coupled control"
    coupled_control = Orocos.name_service.get 'coupled_control'
    Orocos.conf.apply(coupled_control, ['exoter'], :override => true)
    coupled_control.configure
    puts "done"

	puts "Connecting ports"

	# Motion planning outputs
	motion_planning.roverPath.connect_to waypoint_navigation.trajectory

	motion_planning.joints.connect_to coupled_control.manipulatorConfig
	motion_planning.assignment.connect_to coupled_control.assignment
	motion_planning.sizePath.connect_to coupled_control.sizePath

	# Coupled control outputs
	coupled_control.modifiedMotionCommand.connect_to locomotion_control.motion_command
	
	coupled_control.manipulatorCommand.connect_to vortex.manipulator_commands

	# Waypoint navigation outputs
	waypoint_navigation.motion_command.connect_to coupled_control.motionCommand
	waypoint_navigation.current_segment.connect_to coupled_control.currentSegment

	# Locomotion control outputs
	locomotion_control.joints_commands.connect_to vortex.joints_commands

	# Vortex outputs
	vortex.joints_readings.connect_to locomotion_control.joints_readings

	vortex.pose.connect_to waypoint_navigation.pose

	vortex.manipulator_readings.connect_to coupled_control.currentConfig

	motion_planning.start
	coupled_control.start
	vortex.start
	locomotion_control.start
    waypoint_navigation.start


	Readline::readline("Press ENTER to exit\n")
end


