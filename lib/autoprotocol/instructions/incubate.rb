module Autoprotocol

  # Store a sample in a specific environment for a given duration. Once the
  # duration has elapsed, the sample will be returned to the ambient environment
  # until it is next used in an instruction.
  #
  # == Parameters
  #
  # * ref : Ref, str
  #     The container to be incubated
  # * where : {"ambient", "warm_37", "cold_4", "cold_20", "cold_80"}
  #     Temperature at which to incubate specified container
  # * duration : Unit, str
  #     Length of time to incubate container
  # * shaking : bool, optional
  #     Specify whether or not to shake container if available at the specified
  #     temperature
  class Incubate < Instruction
    VALID_INCUBATION_TEMPERATURES = ['ambient', 'warm_30', 'warm_37', 'cold_4', 'cold_20', 'cold_80']

    def initialize(ref:, where:, duration:, shaking: false, co2_percent: 0)
      if !VALID_INCUBATION_TEMPERATURES.include? where
        raise "Specified `where` not contained in: #{VALID_INCUBATION_TEMPERATURES.join(', ')}"
      end
      if where == "ambient" and shaking
        raise "Shaking is not possible for ambient incubation"
      end
      self.data = OpenStruct.new
      self.data.op = 'incubate'
      self.data.ref = ref
      self.data.where = where
      self.data.duration = duration
      self.data.shaking= shaking
      self.data.co2_percent = co2_percent
      super
    end
  end
end
