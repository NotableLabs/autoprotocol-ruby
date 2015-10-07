module Autoprotocol

  # Place specified lid type on specified container
  #
  # === Parameters
  #
  # * ref : str
  #       Container to be convered
  # * lid : {"standard", "universal", "low_evaporation"}, optional
  #       Type of lid to cover container with
  class Cover < Instruction

    LIDS = ["standard", "universal", "low_evaporation"]

    def initialize(ref:,lid: 'standard')
      if lid and !LIDS.include? lid.to_s
        raise ValueError.new "Not a valid lid type #{lid}. Valid lid types: #{LIDS.join(', ')}"
      end
      self.data = OpenStruct.new
      self.data.op = 'cover'
      self.data.ref = ref
      self.data.lid = lid
      super
    end
  end
end
