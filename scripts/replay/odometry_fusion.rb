#library for displaying data
require 'vizkit'
require 'rock/bundle'
require 'orocos'
require 'readline'

include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

bundles_logdir=Bundles.log_dir

#load log file
logfiles_path = ARGV.shift
logfiles_path = "../../logs/log-1" if logfiles_path.nil?
puts(logfiles_path)
system("rm #{logfiles_path}/unit_odometry_fusion.0.log")

log = Orocos::Log::Replay.open(logfiles_path)

Orocos.run 'unit_odometry_fusion' do

    # Configure odometry_fusion
    odometry_fusion = Orocos.name_service.get "odometry_fusion"
    Orocos.conf.apply(odometry_fusion, ['default'], :override => true)
    odometry_fusion.configure

    # Configure evaluation (these are copies of viso2_evaluation defined in the deployment)
    visual_evaluation = TaskContext.get 'visual_evaluation'
    Orocos.conf.apply(visual_evaluation, ['default'], :override => true)
    visual_evaluation.skip_first_n=1
    #visual_evaluation.align_streams=false
    visual_evaluation.configure

    inertial_evaluation = TaskContext.get 'inertial_evaluation'
    Orocos.conf.apply(inertial_evaluation, ['default'], :override => true)
    #inertial_evaluation.align_streams=false
    inertial_evaluation.skip_first_n=10
    inertial_evaluation.configure

    fusion_evaluation = TaskContext.get 'fusion_evaluation'
    Orocos.conf.apply(fusion_evaluation, ['default'], :override => true)
    #fusion_evaluation.align_streams=false
    fusion_evaluation.skip_first_n=10
    fusion_evaluation.configure

    # Connect odometry fusion
    log.threed_odometry.delta_pose_samples_out.connect_to \
        odometry_fusion.inertial_delta_pose_in, :type => :buffer, :size => 10000
    log.spartan.delta_vo_out.connect_to \
        odometry_fusion.visual_delta_pose_in, :type => :buffer, :size => 10000

    # Connect evaluation
    log.vicon.pose_samples.connect_to visual_evaluation.groundtruth_pose
    log.spartan.vo_out.connect_to visual_evaluation.odometry_pose

    log.vicon.pose_samples.connect_to inertial_evaluation.groundtruth_pose
    log.threed_odometry.pose_samples_out.connect_to inertial_evaluation.odometry_pose

    log.vicon.pose_samples.connect_to fusion_evaluation.groundtruth_pose
    odometry_fusion.pose_out.connect_to fusion_evaluation.odometry_pose

    # Log all new ports
    Orocos.log_all_ports(exclude_ports: /log/)

    # Setup readers
    stream_aligner_reader = odometry_fusion.stream_aligner_status.reader
    visual_error_reader = visual_evaluation.perc_error.reader
    inertial_error_reader = inertial_evaluation.perc_error.reader
    fusion_error_reader = fusion_evaluation.perc_error.reader


    # Start tasks
    odometry_fusion.start
    visual_evaluation.start
    inertial_evaluation.start
    fusion_evaluation.start

    # Run log
    log.speed = 1
    while log.step(true)# && log.sample_index <= 10000
        if (ve=visual_error_reader.read_new)
            puts "\n"+(ve*100).round(2).to_s + "% visual drift" +"\n"
            if (ie=inertial_error_reader.read_new)
                puts (ie*100).round(2).to_s + "% inertial drift" +"\n"
            end
            if (fe=fusion_error_reader.read_new)
                puts (fe*100).round(2).to_s + "% fusion drift" +"\n"
            end
        end
    end
    
    # Find resulting logfile
    logfile = `ls -v -- #{Bundles.log_dir}/unit_odometry_fusion.*.log | tail -1`.delete!("\n")

    # Check stream aligner status
    status = "Status:\n"
    if (sa = stream_aligner_reader.read_new)
        sav = sa.streams[0]
        sai = sa.streams[1]
        status += sav.samples_received.to_s + " visual samples reached stream_aligner\n"
        status += sai.samples_received.to_s + " inertial samples reached stream_aligner\n"
        status += sav.samples_dropped_buffer_full.to_s + " visual samples dropped (buffer full)\n" if sav.samples_dropped_buffer_full > 0
        status += sai.samples_dropped_buffer_full.to_s + " inertial samples dropped (buffer full)\n" if sai.samples_dropped_buffer_full > 0
        status += sav.samples_dropped_late_arriving.to_s + " visual samples dropped (late arriving)\n" if sav.samples_dropped_late_arriving > 0
        status += sai.samples_dropped_late_arriving.to_s + " inertial samples dropped (late arriving)\n" if sai.samples_dropped_late_arriving > 0
        status += sav.samples_backward_in_time.to_s + " visual samples dropped (backward in time)\n" if sav.samples_backward_in_time > 0
        status += sai.samples_backward_in_time.to_s + " inertial samples dropped (backward in time)\n" if sai.samples_backward_in_time > 0
        status += sav.buffer_fill.to_s + " visual samples waiting in stream_aligner buffer\n" if sav.buffer_fill>0
        status += sai.buffer_fill.to_s + " inertial samples waiting in stream_aligner buffer\n" if sai.buffer_fill>0
    end
    puts "\n"+status
    File.write("#{logfiles_path}/status.txt", status)

    # Check final drift
    results="Results:\n"
    if (ve=visual_error_reader.read) && (ie=inertial_error_reader.read) && (fe=fusion_error_reader.read)
        results += (ve*100).round(2).to_s + "% visual drift" +"\n"
        results +=  (ie*100).round(2).to_s + "% inertial drift" +"\n"
        results +=  (fe*100).round(2).to_s + "% fusion drift" +"\n"
    end
    puts "\n"+results
    File.write("#{logfiles_path}/results.txt", results)

    sleep(5)
    # Copy logfile to path
    system("cp #{logfile} #{logfiles_path}")
    system("rm -r #{Bundles.log_dir}")
end

Orocos.clear
