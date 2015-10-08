
# Drydock is a command line program that provides a DSL for you to create your
# own build pipeline for your docker images. See {file:README.md} for more
# information and background on the design.
module Drydock

  def self.banner
    "Drydock v#{Drydock.version}"
  end

  def self.build(opts = {}, &blk)
    Project.new(opts).tap do |project|
      dryfile, dryfilename = yield

      Dir.chdir(File.dirname(dryfilename))
      Drydock.logger.info("Working directory set to #{Dir.pwd}")

      begin
        catch :done do
          project.instance_eval(dryfile, dryfilename)
        end
      rescue => e
        Drydock.logger.error("Error processing #{dryfilename}:")
        Drydock.logger.error(message: "#{e.class}: #{e.message}")
        e.backtrace.each do |backtrace|
          Drydock.logger.debug(message: "#{backtrace}", indent: 1)
        end
      ensure
        Drydock.logger.info("Cleaning up")
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
    @logger ||= Logger.new(File.new('/dev/null', 'w+'))
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.version
    version_file = File.join(File.dirname(__FILE__), '..', '..', 'VERSION')
    File.exist?(version_file) ? File.read(version_file).chomp : ""
  end

end
