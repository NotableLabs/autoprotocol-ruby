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
