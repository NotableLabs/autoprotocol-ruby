module Autoprotocol

  # Remove lid from specified container
  #
  # === Parameters
  #
  # * ref : str
  #       Container to remove lid from
  class Uncover < Instruction

    def initialize(ref:,lid: 'standard')
      self.data = OpenStruct.new
      self.data.op = 'uncover'
      self.data.object = ref
      super
    end
  end
end
