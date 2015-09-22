
module Docker

  class Connection

    def raw_request(*args, &block)
      request = compile_request_params(*args, &block)
      log_request(request)
      resource.request(request)
    rescue Excon::Errors::BadRequest => ex
      raise ClientError, ex.response.body
    rescue Excon::Errors::Unauthorized => ex
      raise UnauthorizedError, ex.response.body
    rescue Excon::Errors::NotFound => ex
      raise NotFoundError, ex.response.body
    rescue Excon::Errors::Conflict => ex
      raise ConflictError, ex.response.body
    rescue Excon::Errors::InternalServerError => ex
      raise ServerError, ex.response.body
    rescue Excon::Errors::Timeout => ex
      raise TimeoutError, ex.message
    end

  end

  class Container

    def archive_get(path = '/', &blk)
      query = { 'path' => path }
      connection.get(path_for(:archive), query, response_block: blk)
      self
    end

    def archive_head(path = '/', &blk)
      query = { 'path' => path }
      response = connection.raw_request(:head, path_for(:archive), query, response_block: blk)

      return if response.nil?
      return if response.headers.empty?
      return unless response.headers.key?('X-Docker-Container-Path-Stat')

      ContainerPathStat.new(response.headers['X-Docker-Container-Path-Stat'])
    rescue Docker::Error::NotFoundError
      nil
    end

    def archive_put(path = '/', overwrite: false, &blk)
      headers = { 'Content-Type' => 'application/x-tar' }
      query   = { 'path' => path, 'noOverwriteDirNonDir' => overwrite }

      output = StringIO.new
      blk.call(output)
      output.rewind

      connection.put(path_for(:archive), query, headers: headers, body: output)
      self
    end

  end

  class ContainerPathStat

    def initialize(definition)
      @data = JSON.parse(Base64.decode64(definition))
    end

    def link_target
      @data.fetch('linkTarget')
    end

    def method_missing(method_name, *method_args, &blk)
      if mode.respond_to?(method_name)
        mode.public_send(method_name, *method_args, &blk)
      else
        super
      end
    end

    def mode
      @mode ||= UniversalFileMode.new(@data.fetch('mode'))
    end

    def mtime
      @mtime ||= DateTime.parse(@data.fetch('mtime'))
    end

    def name
      @data.fetch('name')
    end

    def respond_to?(method_name)
      mode.respond_to?(method_name) || super
    end

    def size
      @data.fetch('size')
    end

  end

  # Go implementation of cross-system file modes: https://golang.org/pkg/os/#FileMode
  class UniversalFileMode

    BIT_FIELDS = [
      {directory:        'd'},
      {append_only:      'a'},
      {exclusive:        'l'},
      {temporary:        'T'},
      {link:             'L'},
      {device:           'D'},
      {named_pipe:       'p'},
      {socket:           'S'},
      {setuid:           'u'},
      {setgid:           'g'},
      {character_device: 'c'},
      {sticky:           't'}
    ]

    def self.bit_for(name)
      32 - 1 - BIT_FIELDS.index { |field| field.keys.first == name }
    end

    def self.flags
      BIT_FIELDS.map { |field| field.keys.first }
    end

    def self.file_mode_mask
      0777
    end

    def self.short_flag_for(name)
      BIT_FIELDS.find { |field| field.keys.first == name }.values.first
    end

    def self.type_mode_mask
      value_for(:directory) | value_for(:link) | value_for(:named_pipe) | value_for(:socket) | value_for(:device)
    end

    def self.value_for(name)
      1 << bit_for(name)
    end

    def initialize(value)
      @value = value
    end

    def file_mode
      (@value & self.class.file_mode_mask)
    end

    def flags
      self.class.flags.select { |name| send("#{name}?") }
    end

    def regular?
      (@value & self.class.type_mode_mask) == 0
    end

    def short_flags
      flags.map { |flag| self.class.short_flag_for(flag) }
    end

    def to_s
      short_flags.join
    end

    flags.each do |name|
      define_method("#{name}?") do
        bit_value = self.class.value_for(name)
        (@value & bit_value) == bit_value
      end
    end

  end

end
