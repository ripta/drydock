
module Drydock

  def self.build(opts = {}, &blk)
    Project.new(opts).tap do |project|
      dryfile, dryfilename = yield
      begin
        project.instance_eval(dryfile, dryfilename)
      rescue => e
        Drydock.logger.error("#{e.class}: #{e.message}")
        e.backtrace.each do |backtrace|
          Drydock.logger.error("  #{backtrace}")
        end
      ensure
        project.finalize!
      end
    end
  end

  def self.from(repo, opts = {}, &blk)
    opts = opts.clone
    tag  = opts.delete(:tag, 'latest')

    build(opts).tap do |project|
      project.from(repo, tag)
      yield project
    end
  end

  def self.logger
    @logger || Logger.new(File.new('/dev/null'), 'w+')
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.using(project)
    raise NotImplementedError, "TODO(rpasay)"
  end

  def self.version
    version_file = File.join(File.dirname(__FILE__), '..', '..', 'VERSION')
    File.exist?(version_file) ? File.read(version_file) : ""
  end

end
