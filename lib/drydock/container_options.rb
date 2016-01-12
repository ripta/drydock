
module Drydock
  # Generate container configuration, which can be used to query for a
  # container from the `ImageRepository`.
  class ContainerOptions
    attr_reader :image_id, :opts

    def initialize(image_id, cmd, opts = {})
      @image_id = image_id
      @cmd      = cmd
      @opts     = opts
    end

    def cmd
      return @cmd if @cmd.is_a?(Array)
      ['/bin/sh', '-c', @cmd.to_s]
    end

    def to_h
      to_container_config.tap do |cc|
        env = Array(opts[:env])
        cc[:Env].push(*env) unless env.empty?

        if opts.key?(:expose)
          cc[:ExposedPorts] ||= {}
          opts[:expose].each do |port|
            cc[:ExposedPorts][port] = {}
          end
        end

        (cc[:OnBuild] ||= []).push(opts[:on_build]) if opts.key?(:on_build)

        cc[:MetaOptions] ||= {}
        [:connect_timeout, :read_timeout].each do |key|
          cc[:MetaOptions][key] = opts[key] if opts.key?(key)
          cc[:MetaOptions][key] = opts[:timeout] if opts.key?(:timeout)
        end
      end
    end

    private

    def to_container_config
      ContainerConfig.from(
        Cmd: cmd,
        Tty: opts.fetch(:tty, false),
        Image: image_id
      )
    end
  end
end
