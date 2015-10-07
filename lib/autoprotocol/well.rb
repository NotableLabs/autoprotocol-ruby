module Autoprotocol

  # A Well object describes a single location within a container.
  #
  # Do not construct a Well directly -- retrieve it from the related Container
  # object.
  #
  # === Parameters
  #
  # * container : Container
  #       The Container this well belongs to.
  # * index : integer
  #       The index of this well within the container.
  # * volume : Unit
  #       Theoretical volume of this well.
  # * properties : dict
  #       Additional properties of this well represented as a dictionary.
  class Well
    attr_accessor :container, :index, :name
    attr_reader :properties, :volume
    def initialize(container, index)
      self.container = container
      self.index = index
      @properties = {}
    end

    def properties=(properties)
      raise TypeError, 'properties must be a Hash' if !properties.is_a? Hash
      if self.properties.keys.count > 0
        add_properties properties
      else
        @properties = properties
      end
      self
    end

    def add_properties(properties)
      raise TypeError, 'properties must be a Hash' if !properties.is_a? Hash
      properties.each do |key, value|
        @properties[key] = value
      end
      self
    end

    # Set the theoretical volume of liquid in a Well.
    #
    # === Parameters
    #
    # * vol : str, Unit
    #       Theoretical volume to indicate for a Well.
    def volume=(volume)
      v = Util.convert_to_ul(volume)
      if v > Unit.new(self.container.container_type.well_volume_ul, 'microliter')
        raise ValueError.new "Theoretical volume you are trying to set exceeds the maximum volume of this well."
      end
      @volume = v
      self
    end

    # Return the human readable representation of the integer well index
    # given based on the ContainerType of the Well.
    #
    # Uses the humanize function from the ContainerType class. Refer to
    # `ContainerType.humanize()`_ for more information.
    def humanize
      self.container.humanize(self.index)
    end

    def to_s
      "Well(#{self.container.to_s}, #{self.index.to_s}, #{self.volume.to_s})"
    end
  end
end
