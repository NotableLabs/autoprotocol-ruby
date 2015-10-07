module Autoprotocol

  # The ContainerType class holds the capabilities and properties of a
  # particular container type.
  #
  # === Parameters
  #
  # * name : str
  #     Full name describing a ContainerType.
  # * is_tube : bool
  #     Indicates whether a ContainerType is a tube (container with one well).
  # * well_count : int
  #     Number of wells a ContainerType contains.
  # * well_depth_mm : int
  #     Depth of well(s) contained in a ContainerType in millimeters.
  # * well_volume_ul : int
  #     Maximum volume of well(s) contained in a ContainerType in microliters.
  # * well_coating : str
  #     Coating of well(s) in container (ex. collagen).
  # * sterile : bool
  #     Indicates whether a ContainerType is sterile.
  # * capabilities : array
  #     Array of capabilities associated with a ContainerType (ex. ["spin",
  #       "incubate"]).
  # * shortname : str
  #     Short name used to refer to a ContainerType.
  # * col_count : int
  #     Number of columns a ContainerType contains.
  # * dead_volume_ul : int
  #     Volume of liquid that cannot be aspirated from any given well of a
  #     ContainerType via liquid-handling.
  class ContainerType
    @@attributes = [:is_tube,
                    :well_count,
                    :well_depth_mm,
                    :well_volume_ul,
                    :well_coating,
                    :sterile,
                    :capabilities,
                    :shortname,
                    :col_count,
                    :dead_volume_ul
                   ]
    attr_accessor *@@attributes

    def initialize(params)
      @@attributes.each do |attr|
         instance_variable_set("@#{attr}", params[attr]) if params[attr]
      end
    end

    # Return a robot-friendly well reference from a number of well reference
    # formats.
    #
    # === Example Usage
    #
    #     protocol = Protocol.new()
    #     my_plate = p.ref("my_plate", cont_type: "6-flat", discard: true)
    #     my_plate.robotize("A1") # => 0
    #     my_plate.robotize("5") # => 5
    #     my_plate.robotize(my_plate.well(3)) # => 3
    #
    # === Parameters
    #
    # * well_ref : str, int, Well
    #     Well reference to be robotized in string, integer or Well object
    #     form.
    #
    # === Returns
    #
    # * well_ref : int
    #     Well reference passed as rowwise integer (left-to-right,
    #     top-to-bottom, starting at 0 = A1).
    #
    # === Raises
    #
    # * ValueError
    #       If well reference given exceeds container dimensions.
    def robotize(well_ref)
      if ![String, Fixnum, Well].include? well_ref.class
        raise TypeError.new "ContainerType.robotize(): Well reference given "\
                            "is not of type String, Fixnum, or Well."
      end

      if well_ref.is_a? Well
          well_ref = well_ref.index
      end
      well_ref = well_ref.to_s

      m = /([a-zA-Z])(\d+)$/.match(well_ref)
      if m
        row = m[1].upcase.codepoints.first - 'A'.codepoints.first
        col = m[2].to_i - 1
        well_num = row * self.col_count + col
        # Check bounds
        if row > self.row_count()
          raise ValueError.new "ContainerType.robotize(): Row given exceeds "\
                               "container dimensions."
        end
        if col > self.col_count or col < 0
          raise ValueError.new "ContainerType.robotize(): Col given exceeds "\
                               "container dimensions."
        end
        if well_num > self.well_count
          raise ValueError.new "ContainerType.robotize(): Well given "\
                               "exceeds container dimensions."
        end
        return well_num
      else
        m = /\d+$/.match(well_ref)
        if m
          well_num = m[0].to_i
          # Check bounds
          if well_num > self.well_count or well_num < 0
            raise ValueError.new "ContainerType.robotize(): Well number "\
                                 "given exceeds container dimensions."
          end
          return well_num
        else
          raise ValueError.new "ContainerType.robotize(): Well must be in "\
                               "'A1' format or be an integer. Provided: #{well_ref.to_s}"
        end
      end
    end

    # Return the human readable form of a well index based on the well
    # format of this ContainerType.
    #
    # === Example Usage
    #
    #     protocol = Protocol.new
    #     my_plate = p.ref("my_plate", container_type: "6-flat", discard: true)
    #     my_plate.humanize(0) # => 'A1'
    #     my_plate.humanize(5) # => 'B3'
    #
    # === Parameters
    #
    # well_ref : int
    #   Well reference to be humanized in integer form.
    #
    # === Returns
    #
    # well_ref : str
    #     Well index passed as human-readable form.
    #
    # === Raises
    #
    # ValueError
    #     If well reference given exceeds container dimensions.
    def humanize(well_ref)
      if !well_ref.is_a? Fixnum
        raise TypeError.new "ContainerType.humanize(): Well reference given "\
                            "is not of type Fixnum."
      end
      row, col = self.decompose(well_ref)
      # Check bounds
      if well_ref > self.well_count or well_ref < 0
        raise ValueError.new "ContainerType.humanize(): Well reference "\
                             "given exceeds container dimensions."
      end
      "ABCDEFGHIJKLMNOPQRSTUVWXYZ"[row] + (col + 1).to_s
    end

    # Return the (col, row) corresponding to the given well index.
    #
    # === Parameters
    #
    # * well_ref : str, int
    #       Well index in either human-readable or integer form.
    #
    # === Returns
    #
    # well_ref : array
    #     array containing the column number and row number of the given
    #     well_ref.
    def decompose(idx)
      if ![Fixnum, String, Well].include? idx.class
        raise TypeError.new "Well index given is not of type Fixnum or "\
                            "String."
      end
      idx = self.robotize(idx)
      [idx / self.col_count, idx % self.col_count]
    end

    # Return the number of rows of this ContainerType.
    def row_count
      self.well_count / self.col_count
    end

    CONTAINER_TYPES = {
      "384-flat" => self.new(name: "384-well UV flat-bottom plate",
                                  well_count: 384,
                                  well_depth_mm: nil,
                                  well_volume_ul: 112.0,
                                  well_coating: nil,
                                  sterile: false,
                                  is_tube: false,
                                  capabilities: [],
                                  shortname: "384-flat",
                                  col_count: 24,
                                  dead_volume_ul: 12),
       "384-pcr" => self.new(name: "384-well PCR plate",
                                 well_count: 384,
                                 well_depth_mm: nil,
                                 well_volume_ul: 50.0,
                                 well_coating: nil,
                                 sterile: nil,
                                 is_tube: false,
                                 capabilities: [],
                                 shortname: "384-pcr",
                                 col_count: 24,
                                 dead_volume_ul: 8),
       "384-echo" => self.new(name: "384-well Echo plate",
                                  well_count: 384,
                                  well_depth_mm: nil,
                                  well_volume_ul: 65.0,
                                  well_coating: nil,
                                  sterile: nil,
                                  is_tube: false,
                                  capabilities: [],
                                  shortname: "384-echo",
                                  col_count: 24,
                                  dead_volume_ul: 5),
       "96-flat" => self.new(name: "96-well flat-bottom plate",
                                 well_count: 96,
                                 well_depth_mm: nil,
                                 well_volume_ul: 340.0,
                                 well_coating: nil,
                                 sterile: false,
                                 is_tube: false,
                                 capabilities: [],
                                 shortname: "96-flat",
                                 col_count: 12,
                                 dead_volume_ul: 25),
       "96-flat-uv" => self.new(name: "96-well flat-bottom UV transparent \
                                    plate",
                                    well_count: 96,
                                    well_depth_mm: nil,
                                    well_volume_ul: 340.0,
                                    well_coating: nil,
                                    sterile: false,
                                    is_tube: false,
                                    capabilities: [],
                                    shortname: "96-flat-uv",
                                    col_count: 12,
                                    dead_volume_ul: 25),
       "96-pcr" => self.new(name: "96-well PCR plate",
                                well_count: 96,
                                well_depth_mm: nil,
                                well_volume_ul: 160.0,
                                well_coating: nil,
                                sterile: nil,
                                is_tube: false,
                                capabilities: [],
                                shortname: "96-pcr",
                                col_count: 12,
                                dead_volume_ul: 15),
        "96-deep" => self.new(name: "96-well extended capacity plate",
                                 well_count: 96,
                                 well_depth_mm: nil,
                                 well_volume_ul: 2000.0,
                                 well_coating: nil,
                                 sterile: false,
                                 capabilities: [],
                                 shortname: "96-deep",
                                 is_tube: false,
                                 col_count: 12,
                                 dead_volume_ul: 15),
        "24-deep" => self.new(name: "24-well extended capacity plate",
                                 well_count: 24,
                                 well_depth_mm: nil,
                                 well_volume_ul: 10000.0,
                                 well_coating: nil,
                                 sterile: false,
                                 capabilities: [],
                                 shortname: "24-deep",
                                 is_tube: false,
                                 col_count: 6,
                                 dead_volume_ul: 15),
        "micro-2.0" => self.new(name: "2mL Microcentrifuge tube",
                                   well_count: 1,
                                   well_depth_mm: nil,
                                   well_volume_ul: 2000.0,
                                   well_coating: nil,
                                   sterile: false,
                                   capabilities: [],
                                   shortname: "micro-2.0",
                                   is_tube: true,
                                   col_count: 1,
                                   dead_volume_ul: 15),
        "micro-1.5" => self.new(name: "1.5mL Microcentrifuge tube",
                                   well_count: 1,
                                   well_depth_mm: nil,
                                   well_volume_ul: 1500.0,
                                   well_coating: nil,
                                   sterile: false,
                                   capabilities: [],
                                   shortname: "micro-1.5",
                                   is_tube: true,
                                   col_count: 1,
                                   dead_volume_ul: 15),
        "6-flat" => self.new(name: "6-well cell culture plate",
                                well_count: 6,
                                well_depth_mm: nil,
                                well_volume_ul: 1500.0,
                                well_coating: nil,
                                sterile: false,
                                capabilities: [],
                                shortname: "6-flat",
                                is_tube: false,
                                col_count: 3,
                                dead_volume_ul: 15),
        "1-flat" => self.new(name: "1-well flat-bottom plate",
                                well_count: 1,
                                well_depth_mm: nil,
                                well_volume_ul: 80000.0,
                                well_coating: nil,
                                sterile: false,
                                capabilities: [],
                                shortname: "1-flat",
                                is_tube: false,
                                col_count: 1,
                                dead_volume_ul: 36000)
    }
  end
end
