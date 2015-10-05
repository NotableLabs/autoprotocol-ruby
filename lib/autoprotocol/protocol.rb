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

    def transfer(source, dest, volume, one_source=False, one_tip=False,
                 aspirate_speed=None, dispense_speed=None,
                 aspirate_source=None, dispense_target=None, pre_buffer=None,
                 disposal_vol=None, transit_vol=None, blowout_buffer=None,
                 tip_type=None, new_group=False, **mix_kwargs)

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
      raise NotImplementedError.new 'This method is not yet implemented'
    end

    def self.fill_wells(dst_group, src_group, volume, distribute_target)
      raise NotImplementedError.new 'This method is not yet implemented'
    end

    def flash_freeze(container, duration)
      raise NotImplementedError.new 'This method is not yet implemented'
    end
  end
end
