#library for displaying data
require 'vizkit'
require 'orocos'
require 'readline'

include Orocos
Orocos.initialize


#load log file
logfiles_path = ARGV.shift
logfiles_path = "../../log-6/" if logfiles_path.nil?
puts(logfiles_path)

log = Orocos::Log::Replay.open(logfiles_path)
log.use_sample_time = true

system("rm *.log")
system("rm *.idx")
system("rm *.txt")

sav = nil
sai = nil

Orocos.run 'odometry_fusion::Task' => 'odometry_fusion' do
    odometry_fusion = Orocos.name_service.get "odometry_fusion"

    visual_log = log.spartan.delta_vo_out
    visual_in = odometry_fusion.visual_delta_pose_in
    inertial_log = log.threed_odometry.delta_pose_samples_out
    inertial_in = odometry_fusion.inertial_delta_pose_in

    inertial_log.connect_to inertial_in, :type => :buffer, :size => 10000
    visual_log.connect_to visual_in, :type => :buffer, :size => 10000

    odometry_fusion.inertial_delta_pose_in_period = 0.0001
    odometry_fusion.visual_delta_pose_in_period = 0.0001
    odometry_fusion.aggregator_max_latency = 1
    odometry_fusion.stream_aligner_status_period = 0.1

    odometry_fusion.configure
    odometry_fusion.start

    Orocos.log_all_ports(exclude_ports: /log/)

    log.speed = 1
    sa_reader = odometry_fusion.stream_aligner_status.reader
    while log.step(true) && log.sample_index <= 200
        if (sa = sa_reader.read_new)
            sav = sa.streams[0]
            sai = sa.streams[1]
            puts sa.samples_dropped_late_arriving.to_s + " samples dropped (late arriving) " if sa.samples_dropped_late_arriving > 0
            puts sav.samples_dropped_buffer_full.to_s + " visual samples dropped (buffer full)" if sav.samples_dropped_buffer_full > 0
            puts sai.samples_dropped_buffer_full.to_s + " inertial samples dropped (buffer full)" if sai.samples_dropped_buffer_full > 0
            puts sav.samples_dropped_late_arriving.to_s + " visual samples dropped (late arriving)" if sav.samples_dropped_late_arriving > 0
            puts sai.samples_dropped_late_arriving.to_s + " inertial samples dropped (late arriving)" if sai.samples_dropped_late_arriving > 0
            puts sav.samples_backward_in_time.to_s + " visual samples dropped (backward in time)" if sav.samples_backward_in_time > 0
            puts sai.samples_backward_in_time.to_s + " inertial samples dropped (backward in time)" if sai.samples_backward_in_time > 0
        end
    end

    if (sa = sa_reader.read_new)
        sav = sa.streams[0]
        sai = sa.streams[1]
        puts sa.samples_dropped_late_arriving.to_s + " samples dropped (late arriving) " if sa.samples_dropped_late_arriving > 0
        puts sav.samples_dropped_buffer_full.to_s + " visual samples dropped (buffer full)" if sav.samples_dropped_buffer_full > 0
        puts sai.samples_dropped_buffer_full.to_s + " inertial samples dropped (buffer full)" if sai.samples_dropped_buffer_full > 0
        puts sav.samples_dropped_late_arriving.to_s + " visual samples dropped (late arriving)" if sav.samples_dropped_late_arriving > 0
        puts sai.samples_dropped_late_arriving.to_s + " inertial samples dropped (late arriving)" if sai.samples_dropped_late_arriving > 0
        puts sav.samples_backward_in_time.to_s + " visual samples dropped (backward in time)" if sav.samples_backward_in_time > 0
        puts sai.samples_backward_in_time.to_s + " inertial samples dropped (backward in time)" if sai.samples_backward_in_time > 0
    end
    # log.run
end

logfile = `ls -v -- odometry_fusion.*.log | tail -1`.delete!("\n")
samples_received = `pocolog #{logfile} | grep -A1 pose | grep -o -E '[0-9]+ samples'`.delete!("\n")
puts samples_received + " reached library"
unless sav.nil?
    puts sav.samples_received.to_s + " visual samples reached stream_aligner"
    puts sai.samples_received.to_s + " inertial samples reached stream_aligner"
    puts sav.buffer_fill.to_s + " inertial samples waiting in stream_aligner buffer" if sav.buffer_fill>0
    puts sai.buffer_fill.to_s + " inertial samples waiting in stream_aligner buffer" if sai.buffer_fill>0
end

system("cp #{logfile} #{logfiles_path}")
system("rm *.log")
system("rm *.idx")
system("rm *.txt")
