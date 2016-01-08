
# Drydock is a command line program that provides a DSL for you to create your
# own build pipeline for your docker images. See {file:README.md} for more
# information and background on the design.
module Drydock

  # The application's banner.
  #
  # @return [String] the banner
  def self.banner
    dv = Docker.version
    "Drydock v#{Drydock.version}\n" +
      "  Docker v#{dv['Version']} running on #{dv['Os']}/#{dv['Arch']} #{dv['KernelVersion']}\n" +
      "  Docker Remote API v#{dv['ApiVersion']}"
  rescue
    "Drydock v#{Drydock.version} (unknown Docker version)"
  end

  # Create a new project, then run and finalize the build.
  #
  # @param (see Project#initialize)
  # @option (see Project#initialize)
  # @yield [project] A block that describes the logic on how to search for a
  #   Drydockfile.
  # @yieldparam project [Project] A newly-instantiated project object.
  # @yieldreturn [Array<String>] An array of exactly two elements: the contents
  #   of the Drydockfile, and the path to the Drydockfile. The directory of
  #   the path will be made as the working directory.
  def self.build(build_opts = {}, &blk)
    Project.new(build_opts).tap do |project|
      dryfile, dryfilename = yield project

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
