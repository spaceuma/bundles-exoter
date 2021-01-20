require 'vizkit'
require 'rock/bundle'
require 'readline'

include Orocos

## Initialize orocos ##
Bundles.initialize

Orocos.run 'navigation', 'control', 'simulation', 'vortex::Task' => 'vortex', 'path_planning::Task' => 'path_planning', 'kinova_planning::Task' => 'kinova_planning', 'coupled_control::Task' => 'coupled_control' do

    # setup locomotion_control
    puts "Setting up locomotion_control"
    locomotion_control = Orocos.name_service.get 'locomotion_control'
    Orocos.conf.apply(locomotion_control, ['exoter'], :override => true)
    locomotion_control.configure
    puts "done"

    # setup simulation_vortex
    puts "Setting up simulation_vortex"
    vortex = Orocos.name_service.get 'vortex'
    Orocos.conf.apply(vortex, ['exoter_kinova'], :override => true)
    vortex.configure
    puts "done"

    # setup waypoint_navigation
    puts "Setting up waypoint_navigation"
    waypoint_navigation = Orocos.name_service.get 'waypoint_navigation'
    Orocos.conf.apply(waypoint_navigation, ['default'], :override => true)
    waypoint_navigation.configure
    puts "done"

    # setup path_planning
    puts "Setting up path planning"
    path_planning = Orocos.name_service.get 'path_planning'
    path_planning.keep_old_waypoints = true
    Orocos.conf.apply(path_planning, ['exoter', 'prl_2cm'], :override => true)
    path_planning.configure
    puts "done"

    # setup kinova_planning
    puts "Setting up kinova planning"
    kinova_planning = Orocos.name_service.get 'kinova_planning'
    Orocos.conf.apply(kinova_planning, ['exoter_kinova'], :override => true)
    kinova_planning.configure
    puts "done"

    # setup coupled_control
    puts "Setting up coupled control"
    coupled_control = Orocos.name_service.get 'coupled_control'
    Orocos.conf.apply(coupled_control, ['exoter_kinova'], :override => true)
    coupled_control.configure
    puts "done"

    puts "Connecting ports"

    # Ports connection
    # Path planning outputs
    path_planning.trajectory.connect_to                              kinova_planning.trajectory_port

    # Kinova planning outputs
    kinova_planning.num_waypoints_port.connect_to                    coupled_control.size_path 
    kinova_planning.modified_trajectory_port.connect_to              waypoint_navigation.trajectory
    kinova_planning.joints_motionplanning_matrix_port.connect_to     coupled_control.arm_profile
    kinova_planning.fetching_motionplanning_matrix_port.connect_to   coupled_control.final_movement_matrix_port
    kinova_planning.final_movement_port.connect_to                   coupled_control.kinova_final_movement_port

    # Vortex outputs
    vortex.joints_readings.connect_to                                locomotion_control.joints_readings
    vortex.pose.connect_to                                           waypoint_navigation.pose
 	vortex.manipulator_readings.connect_to                           coupled_control.current_config_vector_double
    vortex.manipulator_readings.connect_to                           kinova_planning.joints_position_port
    vortex.pose.connect_to                                           path_planning.pose
    vortex.pose.connect_to                                           kinova_planning.pose_port
    vortex.goalWaypoint.connect_to                                   path_planning.goalWaypoint
    vortex.sample_position_port.connect_to                           kinova_planning.sample_position_port
    vortex.sample_orientation_port.connect_to                        kinova_planning.sample_orientation_port
    vortex.pose.connect_to                                           coupled_control.pose

    # Locomotion control outputs
    locomotion_control.joints_commands.connect_to                    vortex.joints_commands

    # Waypoint navigation outputs
    waypoint_navigation.motion_command.connect_to                    coupled_control.motion_command
    waypoint_navigation.current_segment.connect_to                   coupled_control.current_segment
    waypoint_navigation.currentWaypoint.connect_to                   coupled_control.current_waypoint
    waypoint_navigation.trajectory_status.connect_to                 kinova_planning.trajectory_status_port

    # Coupled control outputs
    coupled_control.modified_motion_command.connect_to               locomotion_control.motion_command
    coupled_control.manipulator_command_vector_double.connect_to     vortex.manipulator_commands

    # Starting programs
    vortex.start

    # Waiting one second to make sure all data from Vortex has been received
    sleep(1)

    kinova_planning.start
    coupled_control.start
    path_planning.start
    waypoint_navigation.start
    locomotion_control.start


    Readline::readline("Press ENTER to exit\n")

end
                                                     
