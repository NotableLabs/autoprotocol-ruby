module Autoprotocol
  # Read luminesence of indicated wells
  #
  # === Parameters
  #
  # * ref : str, Container
  # * wells : array, WellGroup
  #       WellGroup or array of wells to be measured
  # * dataref : str

  class Luminescence < Instruction
    def initialize(ref:, wells:, dataref:)
      self.data = OpenStruct.new
      self.data.op = 'luminescence'
      self.data.object = ref
      self.data.wells = wells
      self.data.dataref = dataref
      super
    end
  end
end
