require File.expand_path('../../test_helper', __FILE__)

$dummy_container_type = Autoprotocol::ContainerType.new(name: 'dummy',
                                                        well_count: 15,
                                                        well_depth_mm: nil,
                                                        well_volume_ul: 200,
                                                        well_coating: nil,
                                                        sterile: false,
                                                        is_tube: false,
                                                        capabilities: [],
                                                        shortname: 'dummy',
                                                        col_count: 5,
                                                        dead_volume_ul: 15
                                                        )

module Autoprotocol
  class ContainerWellRefTest < Test::Unit::TestCase
    setup do
      @container = Autoprotocol::Container.new(id: nil, container_type: $dummy_container_type)
    end

    should "reference well" do
      assert_kind_of Well, @container.well('B4')
      assert_kind_of Well, @container.well(11)
    end

    should "decompose" do
      assert_equal [2,3], @container.decompose('C4')
      assert_equal [0,0], @container.decompose(0)
    end

    should "identify well" do
      assert_same @container.well('A1'), @container.well(0)
    end

    should "humanize" do
      assert_equal 'A1', @container.well(0).humanize
      assert_equal 'B3', @container.well(7).humanize
      # check bounds
      assert_raise Autoprotocol::ValueError do
        @container.humanize 20
      end
      assert_raise Autoprotocol::ValueError do
        @container.humanize(-1)
      end
    end

    should "robotize" do
      assert_equal 0, @container.robotize('A1')
      assert_equal 7, @container.robotize('B3')
      #check bounds
      assert_raise Autoprotocol::ValueError do
        @container.robotize('A10')
        @container.robotize('J1')
      end
    end
  end

  class ContainerWellGroupConstructionTest < Test::Unit::TestCase
    setup do
      @container = Autoprotocol::Container.new(id: nil, container_type: $dummy_container_type)
    end

    should "all_wells" do
      wells = @container.all_wells
      assert_equal 15, wells.length
      (0..14).each do |i|
        assert_equal i, wells[i].index
      end
    end

    should 'columnwise' do
      wells = @container.all_wells(columnwise: true)
      assert_equal 15, wells.length
      row_count = $dummy_container_type.well_count / $dummy_container_type.col_count
      (0..14).each do |i|
        row, col = @container.decompose(wells[i].index)
        assert_equal i, row + col * row_count
      end
    end

    should 'wells_from' do
      wells = @container.wells_from('A1', 6)
      assert_equal (0..5).to_a, wells.wells.collect { |w| w.index }

      wells = @container.wells_from('B3', 6)
      assert_equal (7..12).to_a, wells.wells.collect { |w| w.index }

      wells = @container.wells_from('A1', 6, columnwise: true)
      assert_equal [0, 5, 10, 1, 6, 11], wells.wells.collect { |w| w.index }

      wells = @container.wells_from('B3', 6, columnwise: true)
      assert_equal [7, 12, 3, 8, 13, 4], wells.wells.collect { |w| w.index }
    end
  end

  class WellVolumeTestCase < Test::Unit::TestCase
    should 'set volume' do
      container = Autoprotocol::Container.new(id: nil, container_type: $dummy_container_type)
      container.well(0).volume = '20:microliter'
      assert_equal 20, container.well(0).volume.value
      assert_equal 'microliter', container.well(0).volume.unit
      assert_same nil, container.well(1).volume
    end

    should 'set_volume_through_group' do
      container = Autoprotocol::Container.new(id: nil, container_type: $dummy_container_type)
      container.all_wells.volume='30:microliter'
      container.all_wells.wells.each do |w|
        assert_equal 30, w.volume.value
      end
    end

    should 'set volume unit conversion' do
      container = Autoprotocol::Container.new(id: nil, container_type: $dummy_container_type)
      container.well(0).volume = '200:nanoliter'
      assert_equal true, container.well(0).volume == Unit.new(0.2, 'microliter')
      container.well(1).volume = '0.1:milliliter'
      assert_equal true, container.well(1).volume == Unit.new(100, 'microliter')
      assert_raise Autoprotocol::ValueError do
        container.well(2).volume = '1:liter'
      end
    end
  end

  class WellPropertyTestCase < Test::Unit::TestCase
    should 'set_properties' do
      container = Autoprotocol::Container.new(id: nil, container_type: $dummy_container_type)
      container.well(0).properties= {'Concentration' => '40:nanogram/microliter'}
      assert_instance_of Hash, container.well(0).properties
      assert_equal ['Concentration'], container.well(0).properties.keys
      assert_equal ['40:nanogram/microliter'], Array.new(container.well(0).properties.values)
    end

    should 'add properties' do
      container = Autoprotocol::Container.new(id: nil, container_type: $dummy_container_type)
      container.well(0).add_properties({'nickname' => 'dummy'})
      assert_equal container.well(0).properties.keys.length, 1
      container.well(0).add_properties({'concentration' => '12:nanogram/microliter'})
      assert_equal container.well(0).properties.keys.length, 2
      container.well(0).add_properties({'property1' => '2', 'ratio' => '1:10'})
      assert_equal container.well(0).properties.keys.length, 4
      assert_raise Autoprotocol::TypeError do
        container.well(0).add_properties ['prop', 'value']
      end
    end

    should 'add properties to well group' do
      container = Autoprotocol::Container.new(id: nil, container_type: $dummy_container_type)
      group = container.wells_from(0, 3)
      group.properties = ({ "property1" => "value1", "property2" => "value2" })
      container.well(0).add_properties({ "property4" => "value4" })
      assert_equal container.well(0).properties.keys.length, 3
      group.wells.each do |well|
        assert_equal true, well.properties.include?('property1')
        assert_equal true, well.properties.include?('property2')
      end
    end
  end

  class WellNameTestCase < Test::Unit::TestCase
    should 'set name' do
      container = Autoprotocol::Container.new(id: nil, container_type: $dummy_container_type)
      container.well(0).name = 'sample'
      assert_equal container.well(0).name, 'sample'
    end
  end
end
