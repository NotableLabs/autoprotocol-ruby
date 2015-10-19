module Autoprotocol
  # A pipette instruction is constructed as a list of groups, executed in
  # order, where each group is a transfer, distribute or mix group.  One
  # disposable tip is used for each group.
  #
  # transfer:
  #
  #     For each element in the transfer list, in order, aspirates the specifed
  #     volume from the source well and dispenses the same volume into the
  #     target well.
  #
  # distribute:
  #
  #     Aspirates sufficient volume from the source well, then dispenses into
  #     each target well the volume requested, in the order specified.
  #     If the total volume to be dispensed exceeds the maximum tip volume
  #     (900 uL), you must either specify allow_carryover to allow the pipette
  #     to return to the source and aspirate another load, or break your group
  #     up into multiple distributes each of less than the maximum tip volume.
  #     Specifying allow_carryover means that the source well could become
  #     contaminated with material from the target wells, so take care to use it
  #     only when you're sure that contamination won't be an issue=for example,
  #     if the target plate is empty.
  #
  # mix:
  #     Mixes the specified wells, in order, by repeated aspiration and
  #     dispensing of the specified volume. The default mixing speed is
  #     50 uL/second, but you may specify a slower or faster speed.
  #
  # Well positions are given using the format :ref/:index
  class Pipette < Instruction
    def initialize(groups:)
      self.data = OpenStruct.new
      self.data.op = 'pipette'
      self.data.groups = groups
      super
    end
  end
end
