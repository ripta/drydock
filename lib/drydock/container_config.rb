
module Drydock
  class ContainerConfig < ::Hash

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

    def self.from(hash)
      return nil if hash.nil?

      self.new.tap do |cfg|
        DEFAULTS.each_pair do |k, v|
          cfg[k] = v
        end
        hash.each_pair do |k, v|
          cfg[k] = v
        end
      end
    end

    # Logic taken from https://github.com/docker/docker/blob/master/runconfig/compare.go
    def ==(other)
      return false if other.nil?

      return false if self['OpenStdin'] || other['OpenStdin']
      return false if self['AttachStdout'] != other['AttachStdout']
      return false if self['AttachStderr'] != other['AttachStderr']

      return false if self['User'] != other['User']
      return false if self['Tty'] != other['Tty']

      return false if self['Cmd'] != other['Cmd']
      return false if Array(self['Env']).sort != Array(other['Env']).sort
      return false if self['Labels'] != other['Labels']
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

    def [](key)
      super(key.to_s)
    end

    def []=(key, value)
      super(key.to_s, value)
    end

  end
end
