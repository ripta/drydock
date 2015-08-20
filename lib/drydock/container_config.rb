
module Drydock
  class ContainerConfig < ::Hash

    DEFAULTS = {
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
      self.new.tap do |cfg|
        DEFAULTS.merge(hash).each_pair do |k, v|
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
      return false if self['Env'] != other['Env']
      return false if self['Labels'] != other['Labels']
      return false if self['Entrypoint'] != other['Entrypoint']

      my_ports = Array(self['ExposedPorts'])
      other_ports = Array(other['ExposedPorts'])
      return false if my_ports.length != other_ports.length
      my_ports.each do |my_port|
        return false unless other_ports.key?(my_port)
      end

      my_vols = Array(self['Volumes'])
      other_vols = Array(self['Volumes'])
      return false if my_vols.length != other_vols.length
      my_vols.each do |my_vol|
        return false unless other_vols.key?(my_vol)
      end

      return true
    end

  end
end
