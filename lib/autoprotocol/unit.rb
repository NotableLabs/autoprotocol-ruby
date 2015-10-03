module Autoprotocol

  # A representation of a measure of volume, duration, temperature, or
  # concentration.
  class Unit
    attr_accessor :value, :unit
    def initialize(value, unit)
      self.value = float(value)
      self.unit = unit
    end

    # Convert a string representation of a unit into a Unit object.
    #
    # === Example
    #
    #     Unit.fromstring("10:microliter")
    #
    #  becomes
    #
    #     Unit(10, "microliter")
    #
    # === Parameters
    #
    # * s : str
    #   String in the format of "value:unit"
    def self.fromstring(s)
      if s.is_a? Unit
        s
      else
        value, unit = s.split(':')
        Unit.new(float(value), unit)
      end
    end

    def to_s
      ":".join([str(self.value), self.unit])
    end

    def _check_type(other)
      if !other.is_a? Unit
        raise ValueError, "Both operands must be of type Unit"
      elsif self.unit != other.unit
        raise ValueError, "unit #{self.unit} is not #{other.unit}"
      end
    end

    def +(other)
      self._check_type(other)
      Unit(self.value + other.value, self.unit)
    end

    def -(other)
      self._check_type(other)
      Unit(self.value - other.value, self.unit)
    end

    def <(other)
      self._check_type(other)
      self.value < other.value
    end

    def <=(other)
      self._check_type(other)
      self.value <= other.value
    end

    def >(other)
      self._check_type(other)
      self.value < other.value
    end

    def >=(other)
      self._check_type(other)
      self.value <= other.value
    end

    def ==(other)
      self._check_type(other)
      self.value == other.value
    end

    def *(other)
      if other.is_a? Unit
        puts "WARNING: Unit.__mul__ and __div__ only support scalar multiplication. Converting #{other.to_s} to #{other.value.to_f}"
        other = other.value
      end
      Unit(self.value * other, self.unit)
    end

    def /(other)
      if other.is_a? Unit
        puts "WARNING: Unit.__mul__ and __div__ only support scalar multiplication. Converting #{other.to_s} to #{other.value.to_f}"
        other = other.value
      end
      Unit(self.value / other, self.unit)
    end

    def <=>(other)
      self._check_type(other)
      Unit(self.value <=> other, self.unit)
    end
  end
end
