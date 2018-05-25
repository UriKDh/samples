working_directory "/app"
stderr_path       "/app/log/unicorn.error.log"
stdout_path       "/app/log/unicorn.log"
worker_processes  1
timeout           60
pid               "/app/tmp/unicorn.pid"
old_pid =         "/app/tmp/unicorn.pid.oldbin"

before_fork do |server, worker|
  # Before forking, kill the master process that belongs to the .oldbin PID.
  # This enables 0 downtime deploys.
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did the job for us
    end
  end
end

after_fork do |server, worker|
  # Creating a pidfile for each worker process
  child_pid = server.config[:pid].sub(".pid", ".#{worker.nr}.pid")
  system "echo #{Process.pid} > #{child_pid}"
end
