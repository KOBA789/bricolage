require 'bricolage/exception'

module Bricolage

  module VacuumLock
    DEFAULT_VACUUM_LOCK_FILE = '/tmp/bricolage.vacuum.lock'
    DEFAULT_VACUUM_LOCK_TIMEOUT = 3600   # 60min

    def vacuum_lock_parameters
      return nil unless ENV['BRICOLAGE_VACUUM_LOCK']
      path, tm = ENV['BRICOLAGE_VACUUM_LOCK'].split(':', 2)
      timeout = tm ? [tm.to_i, 1].max : DEFAULT_VACUUM_LOCK_TIMEOUT
      return path, timeout
    end
    module_function :vacuum_lock_parameters

    def create_lockfile_cmd
      Pathname(__FILE__).parent.parent.parent + 'libexec/create-lockfile'
    end
    module_function :create_lockfile_cmd

    def serialize_vacuum
      path, timeout = vacuum_lock_parameters
      return yield unless path
      create_vacuum_lock_file path, timeout
      begin
        yield
      ensure
        FileUtils.rm_f path
      end
    end
    module_function :serialize_vacuum

    def create_vacuum_lock_file(path, timeout)
      start_time = Time.now
      begin
        File.open(path, File::WRONLY | File::CREAT | File::EXCL) {|f|
          f.puts "#{Time.now}: created by bricolage [#{Process.pid}]"
        }
      rescue Errno::EEXIST
        if Time.now - start_time > timeout
          raise Failure "could not create lock file: #{path} (timeout #{timeout} seconds)"
        end
        sleep 1
        retry
      rescue
        raise
      end
    end
    module_function :create_vacuum_lock_file
  end

end
