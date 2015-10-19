require File.expand_path('../../test_helper', __FILE__)

module Autoprotocol
  class TransferTest < Test::Unit::TestCase
    setup do
      @protocol = Autoprotocol::Protocol.new
    end

    should "single transfer" do
      protocol = Protocol.new
      container = protocol.ref 'test', id: nil, container_type: '96-flat', discard: true
      protocol.transfer container.well(0), container.well(1), '20:microliter'
      assert_equal Unit.new(20, 'microliter'), container.well(1).volume
      assert_equal nil, container.well(0).volume
      assert_equal true,  protocol.instructions.first.json.to_s.include?('transfer')
    end

    should "transfer between wells" do
      container = @protocol.ref "test", id: 'test1', container_type: '384-flat', storage: 'ambient'
      assert_equal @protocol.instructions.length, 0, 'should not be any instructions before appending to empty protocol'
    end

    should "append instructions to protocol" do
      container = @protocol.ref("dummy_ref", container_type: '96-flat', discard: true)
      assert_equal @protocol.instructions.length, 0, 'should not be any instructions before appending to empty protocol'

      @protocol.append(Autoprotocol::Incubate.new(ref: 'dummy_ref', where: 'ambient', duration: '30:second'))
      @protocol.append([
        Autoprotocol::Dispense.new(ref: 'dummy_ref', reagent: 'DMSO', columns: [{column: 0, volume: "50:microliter"},
                                                                                {column: 4, volume: "10:microliter"}
                                                                                                                  ]),
        Autoprotocol::Dispense.new(ref: 'dummy_ref', reagent: 'EX2', columns: [{column: 0, volume: "30:microliter"},
                                                                                {column: 4, volume: "20:microliter"}
                                                                                                                  ])
      ])

     assert_equal @protocol.instructions.length, 3, 'incorrect number of instructions after append'
     assert_equal @protocol.instructions[0].op, 'incubate', 'incorrect instruction appended'
     assert_equal @protocol.instructions[1].op, 'dispense', 'incorrect instruction appended'
     assert_equal @protocol.instructions[2].op, 'dispense', 'incorrect instruction appended'
     # require 'json'
     # puts JSON.pretty_generate @protocol.to_h
    end
  end
end
