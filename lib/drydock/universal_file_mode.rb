
module Drydock
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
