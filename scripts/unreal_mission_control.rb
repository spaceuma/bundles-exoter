require 'vizkit'
require 'rock/bundle'
require 'readline'

include Orocos

## Initialize orocos ##
Bundles.initialize

Orocos.run 'navigation', 'control', 'simulation', 'unreal::Task' => 'unreal', 'path_planning::Task' => 'path_planning', 'mission_control::Task' => 'mission_control', 'coupled_control::Task' => 'coupled_control' do

    # setup locomotion_control
    puts "Setting up locomotion_control"
    locomotion_control = Orocos.name_service.get 'locomotion_control'
    Orocos.conf.apply(locomotion_control, ['exoter'], :override => true)
    locomotion_control.configure
    puts "done"

    # setup simulation_unreal
    puts "Setting up simulation_unreal"
    unreal = Orocos.name_service.get 'unreal'
    Orocos.conf.apply(unreal, ['exoter_kinova'], :override => true)
    unreal.configure
    puts "done"

    # setup waypoint_navigation
    puts "Setting up waypoint_navigation"
    waypoint_navigation = Orocos.name_service.get 'waypoint_navigation'
    #Orocos.conf.apply(waypoint_navigation, ['default'], :override => true)
    Orocos.conf.apply(waypoint_navigation, ['exoter'], :override => true)
    waypoint_navigation.configure
    puts "done"

    # setup path_planning
    puts "Setting up path planning"
    path_planning = Orocos.name_service.get 'path_planning'
    path_planning.keep_old_waypoints = true
    Orocos.conf.apply(path_planning, ['exoter', 'marsTerrain_2cm'], :override => true)
    path_planning.configure
    puts "done"

    # setup mission_control
    puts "Setting up kinova planning"
    mission_control = Orocos.name_service.get 'mission_control'
    Orocos.conf.apply(mission_control, ['unreal_exoter_kinova'], :override => true)
    mission_control.configure
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
    path_planning.trajectory.connect_to                              mission_control.trajectory_port

    # Kinova planning outputs
    mission_control.num_waypoints_port.connect_to                    coupled_control.size_path 
    mission_control.modified_trajectory_port.connect_to              waypoint_navigation.trajectory
    mission_control.modified_trajectory_port.connect_to              coupled_control.trajectory
    mission_control.joints_motionplanning_matrix_port.connect_to     coupled_control.arm_profile
    mission_control.fetching_motionplanning_matrix_port.connect_to   coupled_control.final_movement_matrix_port
    mission_control.final_movement_port.connect_to                   coupled_control.kinova_final_movement_port

    # Vortex outputs
    unreal.joints_readings.connect_to                                locomotion_control.joints_readings
    unreal.pose.connect_to                                           waypoint_navigation.pose
 	unreal.manipulator_readings.connect_to                           coupled_control.current_config_vector_double
    unreal.manipulator_readings.connect_to                           mission_control.joints_position_port
    unreal.pose.connect_to                                           path_planning.pose
    unreal.pose.connect_to                                           mission_control.pose_input
    unreal.goalWaypoint.connect_to                                   mission_control.goal_waypoint_input
    mission_control.goal_waypoint_output.connect_to                  path_planning.goalWaypoint
    unreal.sample_position_port.connect_to                           mission_control.sample_position_port
    unreal.sample_orientation_port.connect_to                        mission_control.sample_orientation_port
    unreal.pose.connect_to                                           coupled_control.pose

    # Locomotion control outputs
    locomotion_control.joints_commands.connect_to                    unreal.joints_commands

    # Waypoint navigation outputs
    waypoint_navigation.motion_command.connect_to                    coupled_control.motion_command
    waypoint_navigation.current_segment.connect_to                   coupled_control.current_segment
    waypoint_navigation.currentWaypoint.connect_to                   coupled_control.current_waypoint
    waypoint_navigation.trajectory_status.connect_to                 mission_control.trajectory_status_port

    # Coupled control outputs
    coupled_control.modified_motion_command.connect_to               locomotion_control.motion_command
    coupled_control.manipulator_command_vector_double.connect_to     unreal.manipulator_commands

    # Starting programs
    unreal.start

    # Waiting one second to make sure all data from Vortex has been received
    sleep(1)

    mission_control.start
    coupled_control.start
    path_planning.start
    waypoint_navigation.start
    locomotion_control.start


    Readline::readline("Press ENTER to exit\n")

end
