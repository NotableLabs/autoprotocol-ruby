module Autoprotocol

  # Dispense specified reagent to specified columns.
  #
  # === Parameters
  #
  # * ref : Ref, str
  #       Container for reagent to be dispensed to.
  # * reagent : str
  #       Reagent to be dispensed to columns in container.
  # * columns : array
  #       Columns to be dispensed to, in the form of an array of hashes specifying
  #       the column number and the volume to be dispensed to that column.
  #       Columns are indexed from 0.
  #       [{"column": <column num>, "volume": <volume>}, ...]
  class Dispense < Instruction

    def initialize(ref:, reagent:, columns:, speed: nil)
      self.data = OpenStruct.new
      self.data.op = 'dispense'
      self.data.ref = ref
      self.data.reagent = reagent
      self.data.columns = columns
      self.data.x_speed_percentage = speed if !speed.nil?
      super
    end
  end
end
