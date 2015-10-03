module Autoprotocol

  # Base class for an instruction that is to later be encoded as JSON
  class Instruction
    require 'ostruct'
    attr_accessor :data

    def initialize(*data)
      self.data.to_h.each do |k, v|
        self.class.__send__ :attr_accessor, k.to_sym
        self.method("#{k}=").call(v)
      end
    end

    # Return instruction object properly encoded as JSON for Autoprotocol
    def json
      JSON.pretty_generate self.data
    end
  end
end
