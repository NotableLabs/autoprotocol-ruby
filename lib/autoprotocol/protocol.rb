module Autoprotocol
  class Protocol
    @@container_types
    attr_accessor :instructions
    attr_accessor :refs

    def initialize(refs:nil, instructions:nil)
      self.refs = refs.nil? ? {} : refs
      self.instructions =  instructions.nil? ? [] : instructions
    end

    # Convert a ContainerType shortname into a ContainerType object.
    #
    # === Parameters
    #
    # * shortname : str
    #     String representing one of the ContainerTypes in the
    #     _CONTAINER_TYPES dictionary.
    #
    # === Returns
    #
    # ContainerType
    #     Returns a Container type object corresponding to the shortname
    #     passed to the function.  If a ContainerType object is passed,
    #     that same ContainerType is returned.
    #
    # === Raises
    #
    # ValueError
    #     If an unknown ContainerType shortname is passed as a parameter.
    def container_type(shortname)
      if shortname.is_a? ContainerType
        shortname
      elsif ContainerType::CONTAINER_TYPES.keys.include? shortname
        ContainerType::CONTAINER_TYPES[shortname]
      else
        raise ValueError.new "Unknown container type #{shortname} (known types=#{ContainerType::CONTAINER_TYPES.keys}"
      end
    end

    # Add a Ref object to the hash of Refs associated with this protocol
    # and return a Container with the id, container type and storage or
    # discard conditions specified.
    #
    # === Example:
    #
    #     protocol = Protocol.new
    #     # ref a new container (no id specified)
    #     sample_ref_1 = protocol.ref("sample_plate_1",
    #                                 cont_type: "96-pcr",
    #                                 discard: True)
    #
    #     # ref an existing container with a known id
    #     sample_ref_2 = protocol.ref("sample_plate_2",
    #                          id: "ct1cxae33lkj",
    #                          cont_type: "96-pcr",
    #                          storage: "ambient")
    #
    # === Autoprotocol Output:
    #
    #     {
    #       "refs": {
    #         "sample_plate_1": {
    #           "new": "96-pcr",
    #           "discard": true
    #         },
    #         "sample_plate_2": {
    #           "id": "ct1cxae33lkj",
    #           "store": {
    #             "where": "ambient"
    #           }
    #         }
    #       },
    #       "instructions": []
    #     }
    #
    # === Parameters
    #
    # * name : str
    #       name of the container/ref being created.
    # * id : str
    #       id of the container being created, from your organization's
    #       inventory on http://secure.transcriptic.com.  Strings representing
    #       ids begin with "ct".
    # * container_type : str, ContainerType
    #       container type of the Container object that will be generated.
    # * storage : {"ambient", "cold_20", "cold_4", "warm_37"}, optional
    #       temperature the container being referenced should be stored at
    #       after a run is completed.  Either a storage condition must be
    #       specified or discard must be set to True.
    # * discard : bool, optional
    #       if no storage condition is specified and discard is set to True,
    #       the container being referenced will be discarded after a run.
    #
    # === Returns
    #
    # container : Container
    #     Container object generated from the id and container type provided.
    #
    # === Raises
    #
    def ref(name, id: nil, container_type:, storage: nil, discard: nil)
      raise RuntimeError.new "Two containers within the same protocol cannot have the same name." if !refs[name].nil?
      opts = {}

      begin
        container_type = self.container_type(container_type)
        if id and container_type
          opts['id'] = id
        elsif container_type
          opts['new'] = container_type.shortname
        end
      rescue Autoprotocol::ValueError => e
        raise RuntimeError.new "You must specify a ref's container type. #{e}"
      end

      if storage
        opts['store'] = { where: storage }
      elsif discard and !storage
        opts['discard'] = discard
      else
        raise RuntimeError, "You must specify either a valid storage
                             condition or set discard=True for a Ref."
      end
      container = Container.new(id: id, container_type: container_type, name: name, storage: storage)
      self.refs[name] = Ref.new(name, opts, container)
      container
    end

    # Append instruction(s) to the list of Instruction objects associated
    # with this protocol.  The other functions on Protocol() should be used
    # in lieu of doing this directly.
    #
    # === Example
    #
    #     protocol = Protocol.new()
    #     protocol.append(Incubate.new(ref: "sample_plate", where: "ambient", duration: "1:hour"))
    #
    # === Autoprotocol Output
    #
    #     "instructions": [
    #         {
    #           "duration": "1:hour",0
    #           "where": "ambient",
    #           "object": "sample_plate",
    #           "shaking": false,
    #           "op": "incubate"
    #         }
    #     ]
    def append(instructions)
      if instructions.is_a? Array
        self.instructions.concat instructions
      else
        self.instructions.push instructions
      end
    end


    # Transfer liquid from one specific well to another.  A new pipette tip
    # is used between each transfer step unless the "one_tip" parameter
    # is set to True.
    #
    # === Example Usage
    #
    #     protocol = Protocol.new()
    #     sample_plate = protocol.ref("sample_plate",
    #                                 ct32kj234l21g,
    #                                 container_type: "96-flat",
    #                                 storage: "warm_37")
    #
    #     # a basic one-to-one transfer:
    #     protocol.transfer(sample_plate.well("B3"),
    #                       sample_plate.well("C3"),
    #                       "20:microliter")
    #
    #     # using a basic transfer in a loop:
    #     (1..12).each do |i|
    #       protocol.transfer(sample_plate.well(i-1),
    #                  sample_plate.well(i),
    #                  "10:microliter")
    #
    #     # transfer liquid from each well in the first column of a 96-well
    #     # plate to each well of the second column using a new tip and
    #     # a different volume each time:
    #     volumes = ["5:microliter", "10:microliter", "15:microliter",
    #                "20:microliter", "25:microliter", "30:microliter",
    #                "35:microliter", "40:microliter"]
    #
    #     protocol.transfer(sample_plate.wells_from(0,8,columnwise: true),
    #                       sample_plate.wells_from(1,8,columnwise: true),
    #                       volumes)
    #
    #     # transfer liquid from wells A1 and A2 (which both contain the same
    #     # source) into each of the following 10 wells:
    #     protocol.transfer(sample_plate.wells_from("A1", 2),
    #                       sample_plate.wells_from("A3", 10),
    #                       "10:microliter",
    #                       one_source: true)
    #
    #     # transfer liquid from wells containing the same source to multiple
    #     # other wells without discarding the tip in between:
    #     protocol.transfer(sample_plate.wells_from("A1", 2),
    #                       sample_plate.wells_from("A3", 10),
    #                       "10:microliter",
    #                       one_source: true,
    #                       one_tip: true)
    #
    # === Parameters
    #
    # * source : Well, WellGroup
    #       Well or wells to transfer liquid from.  If multiple source wells
    #       are supplied and one_source is set to True, liquid will be
    #       transfered from each source well specified as long as it contains
    #       sufficient volume. Otherwise, the number of source wells specified
    #       must match the number of destination wells specified and liquid
    #       will be transfered from each source well to its corresponding
    #       destination well.
    # * dest : Well, WellGroup
    #       Well or WellGroup to which to transfer liquid.  The number of
    #       destination wells must match the number of source wells specified
    #       unless one_source is set to True.
    # * volume : str, Unit, list
    #       The volume(s) of liquid to be transferred from source wells to
    #       destination wells.  Volume can be specified as a single string or
    #       Unit, or can be given as a list of volumes.  The length of a list
    #       of volumes must match the number of destination wells given unless
    #       the same volume is to be transferred to each destination well.
    # * one_source : bool, optional
    #       Specify whether liquid is to be transferred to destination wells
    #       from a group of wells all containing the same substance.
    # * one_tip : bool, optional
    #       Specify whether all transfer steps will use the same tip or not.
    # * mix_after : bool, optional
    #       Specify whether to mix the liquid in the destination well after
    #       liquid is transferred.
    # * mix_before : bool, optional
    #       Specify whether to mix the liquid in the source well before
    #       liquid is transferred.
    # * mix_vol : str, Unit, optional
    #       Volume to aspirate and dispense in order to mix liquid in a wells
    #       before and/or after each transfer step.
    # * repetitions : int, optional
    #       Number of times to aspirate and dispense in order to mix
    #       liquid in well before and/or after each transfer step.
    # * flowrate : str, Unit, optional
    #       Speed at which to mix liquid in well before and/or after each
    #       transfer step.
    # * aspirate speed : str, Unit, optional
    #       Speed at which to aspirate liquid from source well.  May not be
    #       specified if aspirate_source is also specified. By default this is
    #       the maximum aspiration speed, with the start speed being half of
    #       the speed specified.
    # * dispense_speed : str, Unit, optional
    #       Speed at which to dispense liquid into the destination well.  May
    #       not be specified if dispense_target is also specified.
    # * aspirate_source : fn, optional
    #       Can't be specified if aspirate_speed is also specified.
    # * dispense_target : fn, optional
    #       Same but opposite of  aspirate_source.
    # * pre_buffer : str, Unit, optional
    #       Volume of air aspirated before aspirating liquid.
    # * disposal_vol : str, Unit, optional
    #       Volume of extra liquid to aspirate that will be dispensed into
    #       trash afterwards.
    # * transit_vol : str, Unit, optional
    #       Volume of air aspirated after aspirating liquid to reduce presence
    #       of bubbles at pipette tip.
    # * blowout_buffer : bool, optional
    #       If true the operation will dispense the pre_buffer along with the
    #       dispense volume. Cannot be true if disposal_vol is specified.
    # * tip_type : str, optional
    #       Type of tip to be used for the transfer operation.
    # * new_group : bool, optional
    #
    # === Raises
    #
    # * RuntimeError
    #       If more than one volume is specified as a list but the list length
    #       does not match the number of destination wells given.
    # * RuntimeError
    #       If transferring from WellGroup to WellGroup that have different
    #       number of wells and one_source is not true.
    def transfer(source, dest, volume, one_source: false, one_tip: false,
                 aspirate_speed: nil, dispense_speed: nil,
                 aspirate_source: nil, dispense_target: nil, pre_buffer: nil,
                 disposal_vol: nil, transit_vol: nil, blowout_buffer: nil,
                 tip_type: nil, new_group: false, **mix_kwargs)

      source = WellGroup.new(source)
      dest = WellGroup.new(dest)
      opts = []
      len_source = source.wells.length
      len_dest = dest.wells.length

      # Auto-generate well-group if only 1 well specified and using >1 source
      if !one_source
        if len_dest > 1 and len_source == 1
          source = WellGroup.new(source.wells * len_dest)
          len_source = source.wells.length
        end
        if len_dest == 1 and len_source > 1
          dest = WellGroup(dest.wells * len_source)
          len_dest = dest.wells.length
        end
        if len_source != len_dest
            raise RuntimeError.new("To transfer liquid from one well or \
                                   multiple wells containing the same \
                                   source, set one_source to true. To  \
                                   transfer liquid from multiple wells to a \
                                   single destination well, specify only one \
                                   destination well. Otherwise, you must \
                                   specify the same number of source and \
                                   destination wells to do a one-to-one \
                                   transfer.")
        end
      end

      # Auto-generate list from single volume, check if list length matches
      if volume.is_a?(String) || volume.is_a?(Unit)
        if len_dest == 1 && !one_source
          volume = [Unit.fromstring(volume)] * len_source
        else
          volume = [Unit.fromstring(volume)] * len_dest
        end
      elsif volume.is_a?(Array) && volume.length == len_dest
        volume = volume.collect{ |x| Unit.fromstring(x) }
      else
        raise RuntimeError("Unless the same volume of liquid is being \
                           transferred to each destination well, each \
                           destination well must have a corresponding \
                           volume in the form of a list.")
      end

      # Ensure enough volume in single well to transfer to all dest wells
      if one_source
        begin
          source_vol = source.wells.collect{ |s| s.volume }
          if volume.sum{ |a| a.value } > source_vol.sum{ |a| a.value }
            raise RuntimeError.new("There is not enough volume in the source well(s) specified to complete \
                                 the transfers.")
          end
          if len_source >= len_dest and source_vol.zip(volume).collect{ |i,j| i > j }.all?
            sources = source.wells[0..len_dest - 1]
            destinations = dest.wells
            volumes = volume
          else
            sources = []
            source_counter = 0
            destinations = []
            volumes = []
            s = source.wells[source_counter]
            vol = s.volume
            max_decimal_places = 12
            dest.wells.each_with_index do |d, idx|
              vol_d = volume[idx]
              while vol_d > Unit.fromstring("0:microliter") do
                if vol > vol_d
                  sources.append(s)
                  destinations.append(d)
                  volumes.append(vol_d)
                  vol -= vol_d
                  vol.value = vol.value.round(max_decimal_places)
                  vol_d -= vol_d
                  vol_d.value = vol_d.value.round(max_decimal_places)
                else
                  sources.append(s)
                  destinations.append(d)
                  volumes.append(vol)
                  vol_d -= vol
                  vol_d.value = vol_d.value.round(max_decimal_places)
                  source_counter += 1
                  if source_counter < len_source
                    s = source.wells[source_counter]
                    vol = s.volume
                  end
                end
              end
            end
          end
          source = WellGroup.new(sources)
          dest = WellGroup.new(destinations)
          volume = volumes
        rescue ValueError, AttributeError => e
          raise RuntimeError.new "When transferring liquid from multiple wells containing the same substance to \
                                 multiple other wells, each source Well must have a volume attribute (aliquot) \
                                 associated with it."
        end
      end
      (0..source.length - 1).collect{ |i| { source: source.wells[i], destination: dest.wells[i], volume: volume[i]} }.each do |transfer|
        volume = Util.convert_to_ul(transfer[:volume])
        source = transfer[:source]
        destination = transfer[:destination]
        if volume > Unit.new(750, "microliter")
          diff = Unit.fromstring(volume)
          while diff > Unit(750, "microliter") do
            self.transfer(source, destination, "750:microliter", one_source, one_tip,
                          aspirate_speed, dispense_speed, aspirate_source,
                          dispense_target, pre_buffer, disposal_vol,
                          transit_vol, blowout_buffer, tip_type,
                          new_group, **mix_kwargs)
            diff -= Unit(750, "microliter")
          end

          self.transfer(source, destination, diff,  one_source, one_tip,
                        aspirate_speed, dispense_speed, aspirate_source,
                        dispense_target, pre_buffer, disposal_vol,
                        transit_vol, blowout_buffer, tip_type,
                        new_group, **mix_kwargs)
          next
        end

        # Organize transfer options into dictionary (for json parsing)
        xfer = {
            "from" => source,
            "to" => destination,
            "volume" => volume
        }
        # Volume accounting
        if destination.volume
          destination.volume += volume
        else
          destination.volume = volume
        end
        if source.volume
          source.volume -= volume
        end

        # mix before and/or after parameters
        if mix_kwargs && !mix_kwargs.empty? && (!mix_kwargs.include?("mix_before") && mix_kwargs.include?("mix_after"))
            raise RuntimeError.new "If you specify mix arguments on transfer() \
                                   you must also specify mix_before and/or \
                                   mix_after=True."
        end
        if mix_kwargs.include? "mix_before"
          xfer["mix_before"] = {
            "volume" => [mix_kwargs["mix_vol_b"], mix_kwargs["mix_vol"], volume/2].each {|v| break v if v},
            "repetitions" => [mix_kwargs["repetitions_b"], mix_kwargs["repetitions"], 10].each {|r| break r if r},
            "speed" => [mix_kwargs["flowrate_b"], mix_kwargs["flowrate"], "100:microliter/second"].each {|s| break s if s}
          }
        end
        if mix_kwargs.include? "mix_after"
          xfer["mix_after"] = {
            "volume" => [mix_kwargs["mix_vol_a"], mix_kwargs["mix_vol"], volume/2].each {|v| break v if v},
            "repetitions" => [mix_kwargs["repetitions_a"], mix_kwargs["repetitions"], 10].each {|r| break r if r},
            "speed" => [mix_kwargs["flowrate_a"], mix_kwargs["flowrate"], "100:microliter/second"].each {|sp| break sp if sp}
          }
        end
        # Append transfer options
        opt_list = ["aspirate_speed", "dispense_speed"]
        opt_list.each do |option|
          xfer[option] = option
        end
        x_opt_list = ["x_aspirate_source", "x_dispense_target",
                      "x_pre_buffer", "x_disposal_vol", "x_transit_vol",
                      "x_blowout_buffer"]
        x_opt_list.each do |x_option|
          xfer[x_option] = x_option[2..-1]
        end
        if volume.value > 0
          opts.push xfer
        end

        trans = {}
        trans['x_tip_type'] = tip_type
        if one_tip
          trans["transfer"] = opts
          if new_group
            self.append(Pipette.new([trans]))
          else
            self._pipette([trans])
          end
        else
          opts.each do |x|
            trans = {}
            trans['x_tip_type'] = tip_type
            trans["transfer"] = [x]
            if new_group
              self.append(Pipette.new([trans]))
            else
              self._pipette([trans])
            end
          end
        end
      end
    end

    # Dispense the specified amount of the specified reagent to every well
    # of a container using a reagent dispenser.
    #
    # === Example Usage
    #
    #     protocol = Protocol.new()
    #     sample_plate = protocol.ref("sample_plate",
    #                                 nil,
    #                                 container_type: "96-flat",
    #                                 storage: "warm_37")
    #
    #     protocol.dispense_full_plate(sample_plate,
    #                                 "water",
    #                                 "100:microliter")
    #
    # === Autoprotocol Output
    #
    #     "instructions": [
    #         {
    #           "reagent": "water",
    #           "object": "sample_plate",
    #           "columns": [
    #             {
    #               "column": 0,
    #               "volume": "100:microliter"
    #             },
    #             {
    #               "column": 1,
    #               "volume": "100:microliter"
    #             },
    #             {
    #               "column": 2,
    #               "volume": "100:microliter"
    #             },
    #             {
    #               "column": 3,
    #               "volume": "100:microliter"
    #             },
    #             {
    #               "column": 4,
    #               "volume": "100:microliter"
    #             },
    #             {
    #               "column": 5,
    #               "volume": "100:microliter"
    #             },
    #             {
    #               "column": 6,
    #               "volume": "100:microliter"
    #             },
    #             {
    #               "column": 7,
    #               "volume": "100:microliter"
    #             },
    #             {
    #               "column": 8,
    #               "volume": "100:microliter"
    #             },
    #             {
    #               "column": 9,
    #               "volume": "100:microliter"
    #             },
    #             {
    #               "column": 10,
    #               "volume": "100:microliter"
    #             },
    #             {
    #               "column": 11,
    #               "volume": "100:microliter"
    #             }
    #           ],
    #           "op": "dispense"
    #         }
    #     ]
    #
    # === Parameters
    #
    # * ref : Container
    #       Container for reagent to be dispensed to.
    # * reagent : str
    #       Reagent to be dispensed to columns in container.
    # * volume : Unit, str
    #       Volume of reagent to be dispensed to each well
    # * speed_percentage : int, optional
    #       Integer between 1 and 100 that represents the percentage of the
    #       maximum speed at which liquid is dispensed from the reagent
    #       dispenser.
    def dispense_full_plate(ref, reagent, volume, speed_percentage: nil)
      if speed_percentage.nil? and
         (speed_percentage > 100 or speed_percentage < 1)
         raise RuntimeError.new "Invalid speed percentage specified."
      end
      columns = []
      (0..ref.container_type.col_count).each do |col|
        columns.append({"column" => col, "volume" => volume})
      end
      self.dispense(ref, reagent, columns, speed_percentage)
    end

    # Read luminescence of indicated wells.
    #
    # === Example Usage
    #
    #     protocol = Protocol.new()
    #     sample_plate = protocol.ref("sample_plate",
    #                                 nil,
    #                                 container_type: "96-flat",
    #                                 storage: "warm_37")
    #
    #     protocol.luminescence(sample_plate, sample_plate.wells_from(0,12),
    #                           "test_reading")
    #
    # Autoprotocol Output
    #
    #     "instructions": [
    #         {
    #           "dataref": "test_reading",
    #           "object": "sample_plate",
    #           "wells": [
    #             "A1",
    #             "A2",
    #             "A3",
    #             "A4",
    #             "A5"
    #             "A6",
    #             "A7",
    #             "A8",
    #             "A9",
    #             "A10",
    #             "A11",
    #             "A12"
    #           ],
    #           "op": "luminescence"
    #         }
    #       ]
    #
    # === Parameters
    #
    # * ref : str, Container
    #       Container to plate read.
    # * wells : array, WellGroup
    #       WellGroup or array of wells to be measured
    # * dataref : str
    #       Name of this dataset of measured luminescence readings.
    def luminescence(ref, wells, dataref)
      if wells.is_a? WellGroup
        wells = wells.indices()
      end
      self.instructions.append(Luminescence.new(ref: ref, wells: wells, dataref: dataref))
    end

    # Move plate to designated thermoisolater or ambient area for incubation
    # for specified duration.
    #
    # === Example Usage
    #
    #     protocol = Protocol.new()
    #     sample_plate = protocol.ref("sample_plate",
    #                                 nil,
    #                                 "96-pcr",
    #                                 storage: "warm_37")
    #
    #     # a plate must be sealed/covered before it can be incubated
    #     protocol.seal(sample_plate)
    #     protocol.incubate(sample_plate, "warm_37", "1:hour", shaking: true)
    #
    # Autoprotocol Output:
    #
    #     "instructions": [
    #         {
    #           "object": "sample_plate",
    #           "op": "seal"
    #         },
    #         {
    #           "duration": "1:hour",
    #           "where": "warm_37",
    #           "object": "sample_plate",
    #           "shaking": true,
    #           "op": "incubate",
    #           "co2_percent": 0
    #         }
    #       ]
    def incubate(ref, where, duration, shaking: false, co2: 0)
      self.instructions.append(Incubate.new(ref:ref, where:where, duration:duration, shaking:shaking, co2:co2))
    end

    # Returns the entire protocol as a hash
    #
    # == Example
    #
    #    require 'autoprotocol'
    #    require 'json'
    #
    #    protocol = Protocol.new
    #    sample_ref = protocol.ref('sample_plate_2',
    #                              id: 'ct1cxae33lkj',
    #                              container_type: '96-pcr',
    #                              storage: 'ambient')
    #    protocol.seal(sample_ref)
    #    protocol.incubate(sample_ref, 'warm_37', '20:minute')
    #    puts protocol.to_h.to_json
    #
    #    # Produces the following json:
    #    {
    #       {
    #         "refs": {
    #           "sample_plate_2": {
    #             "id": "ct1cxae33lkj",
    #             "store": {
    #               "where": "ambient"
    #             }
    #           }
    #         },
    #         "instructions": [
    #           {
    #             "object": "sample_plate_2",
    #             "op": "seal"
    #           },
    #           {
    #             "duration": "20:minute",
    #             "where": "warm_37",
    #             "object": "sample_plate_2",
    #             "shaking": false,
    #             "op": "incubate"
    #           }
    #         ]
    #       }
    #    }
    def to_h
      outs = {}

      self.refs.each do |n, ref|
        ref.container._wells.each do |well|
          if well.name
            if !outs.keys.include? n
              outs[n] = {}
            end
            outs[n][well.index.to_s] = {name: well.name}
          end
        end
      end

      output = { refs: {}, instructions: {} }
      refs.map { |key, value| output[:refs][key] = value.opts }
      output[:instructions] = self.instructions.collect{ |x| self._refify(x.data.to_h) }
      output[:outs] = outs if !outs.empty?
      output
    end

    def _refify(op_data)
      case op_data
      when Hash
        ref_hash = {}
        op_data.each do |k, v|
          ref_hash[k.to_sym] = self._refify(v)
        end
        ref_hash
      when Array
        op_data.collect{ |data| self._refify(data) }
      when Well
        self._ref_for_well(op_data)
      when WellGroup
        op_data.wells.collect{|w| self._ref_for_well(w)}
      when Container
        self._ref_for_container(op_data)
      when Unit
        op_data.to_s
      else
        op_data
      end
    end

    def _ref_for_well(well)
      "#{self._ref_for_container(well.container)}/#{well.index.to_s}"
    end

    def _ref_for_container(container)
      refs.each do |k,v|
        return k if v.container == container
      end
    end

    def _ref_containers_and_wells(params)
      raise NotImplementedError.new 'This method is not yet implemented'
    end

    # Append given pipette groups to the protocol
    def _pipette(groups)
      if self.instructions.length > 0 && self.instructions[-1].op == 'pipette'
        self.instructions[-1].groups += groups
      else
        self.instructions.append(Pipette.new(groups: groups))
      end
    end

    def self.fill_wells(dst_group, src_group, volume, distribute_target)
      raise NotImplementedError.new 'This method is not yet implemented'
    end

    def flash_freeze(container, duration)
      raise NotImplementedError.new 'This method is not yet implemented'
    end
  end
end
