
module Drydock
  # A comparable way of storing the `ContainerConfig` hash of a `Docker::Image#info`.
  #
  # @example
  #   ContainerConfig.from(Cmd: '/bin/ls -l')
  class ContainerConfig < ::Hash

    # The available options and their default values.
    DEFAULTS = {
      'MetaOptions'  => {},
      'OpenStdin'    => false,
      'AttachStdin'  => false,
      'AttachStdout' => false,
      'AttachStderr' => false,
      'User'         => '',
      'Tty'          => false,
      'Cmd'          => nil,
      'Env'          => ['PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'],
      'Labels'       => nil,
      'Entrypoint'   => nil,
      'ExposedPorts' => nil,
      'Volumes'      => nil
    }

    # Build a new ContainerConfig from a hash. Returns `nil` if the `hash` is nil.
    # If a key is not provided, its default value is used.
    #
    # Each key may be a camel-cased string or a camel-cased symbol.
    #
    # @param [#each_pair, nil] hash the source hash, which may be sparse
    # @return [ContainerConfig, nil]
    # @example The following examples produce the same object:
    #   ContainerConfig.from(AttachStdout: true)
    #   ContainerConfig.from('AttachStdout' => true)
    #   ContainerConfig.new.tap do |cfg|
    #     cfg.attach_stdout = true
    #   end
    def self.from(hash)
      return nil if hash.nil?

      new.tap do |cfg|
        hash.each_pair do |k, v|
          cfg[k] = v
        end
      end
    end

    # Create a new ContainerConfig with the default values pre-populated.
    def initialize
      DEFAULTS.each_pair do |k, v|
        begin
          self[k] = v.dup
        rescue TypeError
          self[k] = v
        end
      end
    end

    # Logic taken from https://github.com/docker/docker/blob/master/runconfig/compare.go
    # Last updated to conform to docker v1.9.1
    #
    # @param [ContainerConfig, nil] other the other object to compare to
    def ==(other)
      return false if other.nil?

      return false if self['OpenStdin'] || other['OpenStdin']
      return false if self['AttachStdout'] != other['AttachStdout']
      return false if self['AttachStderr'] != other['AttachStderr']

      return false if self['User'] != other['User']
      return false if self['Tty'] != other['Tty']

      return false if self['Cmd'] != other['Cmd']
      return false if Array(self['Env']).sort != Array(other['Env']).sort
      return false if (self['Labels'] || {}) != (other['Labels'] || {})
      return false if self['Entrypoint'] != other['Entrypoint']

      my_ports = self['ExposedPorts'] || {}
      other_ports = other['ExposedPorts'] || {}
      return false if my_ports.keys.size != other_ports.keys.size
      my_ports.keys.each do |my_port|
        return false unless other_ports.key?(my_port)
      end

      my_vols = self['Volumes'] || {}
      other_vols = other['Volumes'] || {}
      return false if my_vols.keys.size != other_vols.keys.size
      my_vols.keys.each do |my_vol|
        return false unless other_vols.key?(my_vol)
      end

      return true
    end

    # Retrieve the value of option `key`. The `key` must be in camel case, e.g.,
    # `AttachStdout`. See DEFAULTS for the correct capitalization.
    def [](key)
      super(key.to_s)
    end

    # Set an option `key` to `value`. The `key` must be in camel case, e.g.,
    # `AttachStdout`. See DEFAULTS for the correct capitalization.
    def []=(key, value)
      super(key.to_s, value)
    end

    # Handle convenience methods in `snake_case`. The following pairs of lines
    # achieve the same result:
    #
    #   cfg[:AttachStdout] = true
    #   cfg.attach_stdout = true
    #
    #   cfg[:ExposedPorts]
    #   cfg.exposed_ports
    def method_missing(name, *args, &_block)
      is_setter, attr_name = normalize(name)

      if DEFAULTS.key?(attr_name)
        self[attr_name] = args.first if is_setter
        self[attr_name]
      else
        super
      end
    end

    def respond_to_missing?(name, _include_private = false)
      _, attr_name = normalize(name)
      DEFAULTS.key?(attr_name)
    end

    private

    def camelize(name)
      name = name.to_s.dup
      return name if name.match(/^[A-Z]/)

      name.sub(/^[a-z\d]*/) { $&.capitalize }
          .gsub(/(?:_)([a-z\d]*)/i) { $1.capitalize }
    end

    def normalize(method_name)
      [
        method_name.to_s.end_with?('='),
        camelize(method_name.to_s.sub(/=$/, ''))
      ]
    end

  end
end
