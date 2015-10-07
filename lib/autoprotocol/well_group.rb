module Autoprotocol
  # A logical grouping of Wells.
  #
  # Wells in a WellGroup do not necessarily need to be in the same container.
  #
  # === Parameters
  #
  # * wells : list
  #       Array of Well objects contained in this WellGroup.
  class WellGroup
    attr_accessor :wells

    def initialize(wells)
      if wells.is_a? Well
        wells = [wells]
      elsif wells.is_a? WellGroup
        wells = well.wells
      end
      self.wells = wells
    end

    # Set the same properties for each Well in a WellGroup.
    #
    # === Parameters
    #
    # properties : dict
    #   Hash of properties to set on Well(s).
    def properties=(properties)
      if !properties.is_a? Hash
        raise TypeError.new "Properties given is not of type 'hash'."
      end
      self.wells.each do |w|
        w.properties = properties
      end
      self
    end

    # Set the volume of every well in the group to vol.
    #
    # === Parameters
    #
    # * vol : Unit, str
    #       Theoretical volume of each well in the WellGroup.
    def volume=(vol)
      if !vol.is_a? Unit and !vol.is_a? String
        raise TypeError.new "Volume given is not of type Unit or 'str'."
      end
      self.wells.each do |w|
        w.volume = vol
      end
      self
    end

    # Return the indices of the wells in the group in human-readable form,
    # given that all of the wells belong to the same container.
    def indices
      indices = []
      self.wells.each do |w|
        if w.container != self.wells[0].container
          raise AutoprotocolError.new "All wells in \
            WellGroup must belong to the same container to get their \
            indices"
        end
        indices.push w.humanize
      end
      indices
    end

    # Append another well to this WellGroup.
    #
    # === Parameters
    #
    # * other : Well
    #       Well to append to this WellGroup.
    def append(other)
      if !other.is_a? Well
        raise TypeError.new "Input given is not of type 'Well'."
      else
        self.wells.push(other)
      end
    end

    def [](key)
      self.wells[key]
    end

    def to_s
      "WellGroup(#{self.wells.to_s})"
    end

    def length
      self.wells.length
    end

    # Append a Well or Wells from another WellGroup to this WellGroup.
    #
    # === Parameters
    #
    # * other : Well, WellGroup
    def +(other)
      if !other.is_a? Well and !other.is_a? WellGroup
        raise RuntimeError.new "You can only add a Well or WellGroups together."
      end
      if other.is_a? Well
        WellGroup.new(self.wells.push(other))
      else
        WellGroup.new(self.wells + other.wells)
      end
    end
  end
end
