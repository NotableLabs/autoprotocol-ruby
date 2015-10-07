module Autoprotocol
  # A reference to a specific physical container (e.g. a tube or 96-well
  # microplate).
  #
  # Every Container has an associated ContainerType, which defines the well
  # count and arrangement, amongst other properties.
  #
  # There are several methods on Container which present a convenient interface
  # for defining subsets of wells on which to operate. These methods return a
  # WellGroup.
  #
  # Containers are usually declared using the Protocol.ref method.
  #
  # === Parameters
  #
  # * name : str
  #       name of the container/ref being created.
  # * id : string
  #       Alphanumerical identifier for a Container.
  # * container_type : ContainerType
  #       ContainerType associated with a Container.
  class Container
    attr_accessor :name, :id, :container_type, :storage, :_wells
    def initialize(id: nil, container_type: nil, name: nil, storage: nil)
      self.name = name
      self.id = id
      self.container_type = container_type
      self.storage = storage
      self._wells = []
      (0..container_type.well_count - 1).each do |index|
        self._wells.push Well.new(self, index)
      end
    end

    # Return a Well object representing the well at the index specified of
    # this Container.
    #
    # === Parameters
    #
    # * i : int, str
    #       Well reference in the form of an integer (ex: 0) or human-readable
    #       string (ex: "A1").
    def well(i)
      if !i.is_a? String and !i.is_a? Fixnum
        raise TypeError.new "Well reference given is not of type Fixnum or String."
      end
      self._wells[self.robotize(i)]
    end

    # Return a WellGroup containing references to wells corresponding to the
    # index or indices given.
    #
    # === Parameters
    #
    # * args : str, int, aray
    #       Reference or array of references to a well index either as an
    #       integer or a string.
    def wells(*args)
      if args[0].is_a? Array
        wells = args[0]
      else
        wells = []
        args.each do |a|
          if a.is_a? Array
            wells.concat a
          else
            wells.push a
          end
        end
      end
      wells.each do |w|
        if !w.is_a? String and !w.is_a? Integer and !w.is_a? Array
          raise TypeError.new "Well reference given is not of type 'int', 'str' or 'list'."
        end
      end
      WellGroup.new wells.collect{ |w| self.well(w) }
    end

    # Return the integer representation of the well index given, based on
    # the ContainerType of the Container.
    #
    # Uses the robotize function from the ContainerType class. Refer to
    # `ContainerType.robotize()`_ for more information.
    def robotize(well_ref)
      if !well_ref.is_a? String and !well_ref.is_a? Integer and !well_ref.is_a? Well
        raise TypeError.new "Well reference given is not of type String, Integer, or 'Well'."
      end
      self.container_type.robotize(well_ref)
    end

    # Return the human readable representation of the integer well index
    # given based on the ContainerType of the Container.
    #
    # Uses the humanize function from the ContainerType class. Refer to
    # `ContainerType.humanize()`_ for more information.
    def humanize(well_ref)
      if !well_ref.is_a? Integer
        raise TypeError.new "Well reference given is not of type 'int'."
      end
      self.container_type.humanize(well_ref)
    end

    # Return a tuple representing the column and row number of the well
    # index given based on the ContainerType of the Container.
    #
    # Uses the decompose function from the ContainerType class. Refer to
    # `ContainerType.decompose()`_ for more information.
    def decompose(well_ref)
      if !well_ref.is_a? Integer and !well_ref.is_a? String and !well_ref.is_a? Well
        raise TypeError.new "Well reference given is not of type 'int', 'str' or Well."
      end
      self.container_type.decompose(well_ref)
    end

    # Return a WellGroup representing all Wells belonging to this Container.

    # Parameters
    # ----------
    # columnwise : bool, optional
    #     returns the WellGroup columnwise instead of rowwise (ordered by
    #     well index).
    def all_wells(columnwise: false)
      if columnwise
        num_cols = self.container_type.col_count
        num_rows = self.container_type.well_count.to_i / num_cols.to_i
        wells = []
        (0..num_cols - 1).each do |col|
          (0..num_rows - 1).each do |row|
            wells.push self._wells[row * num_cols + col]
          end
        end
        WellGroup.new wells
      else
        WellGroup.new self._wells
      end
    end

    # Return a WellGroup of all wells on a plate excluding wells in the top
    # and bottom rows and in the first and last columns.
    #
    # === Parameters
    #
    # * columnwise : bool, optional
    #       returns the WellGroup columnwise instead of rowwise (ordered by
    #       well index).
    def inner_wells(columnwise=false)
      num_cols = self.container_type.col_count
      num_rows = self.container_type.row_count
      inner_wells = []
      if columnwise
        (1..num_cols - 1).each do |c|
          wells = []
          (1..num_rows - 1).each do |r|
            wells.push (r*num_cols) + c
          end
          inner_wells.extend(wells)
        end
      else
        well = num_cols
        (1..num_rows - 1).each do |i|
          inner_wells.push ((well + 1)..(well+(num_cols - 1))).to_a
          well += num_cols
        end

        inner_wells = inner_wells.collect{|x| self_well[x]}
      end
      WellGroup.new inner_wells
    end

    # Return a WellGroup of Wells belonging to this Container starting from
    # the index indicated (in integer or string form) and including the
    # number of proceeding wells specified. Wells are counted from the
    # starting well rowwise unless columnwise is True.
    #
    # === Parameters
    #
    # * start : Well, int, str
    #       Starting well specified as a Well object, a human-readable well
    #       index or an integer well index.
    # * num : int
    #       Number of wells to include in the Wellgroup.
    # * columnwise : bool, optional
    #       Specifies whether the wells included should be counted columnwise
    #       instead of the default rowwise.
    def wells_from(start, num, columnwise: false)
      if !start.is_a? String and !start.is_a? Fixnum and !start.is_a? Well
        raise TypeError.new "Well reference given is not of type String, Fixnum, or Well."
      end
      if !num.is_a? Fixnum
        raise TypeError.new "Number of wells given is not of type Fixnum."
      end

      start = self.robotize(start)
      if columnwise
        row, col = self.decompose(start)
        num_rows = self.container_type.row_count()
        start = col * num_rows + row
      end
      WellGroup.new self.all_wells(columnwise: columnwise).wells[start .. start + num - 1]
    end

    # Return a WellGroup of Wells corresponding to the selected quadrant of
    # this Container.
    #
    # This is only applicable to 384-well plates.
    #
    # === Parameters
    #
    # * quad : int
    #       Specifies the quadrant number of the well (ex. 2)
    def quadrant(quad)
      if quad.is_a? String
        quad = Unit.quad_ind_to_num(quad)
      end
      if self.container_type.well_count == 96
        if quad == 0
          return self._wells
        else
          raise RuntimeError.new "0 or 'A1' is the only valid quadrant for a 96-well plate."
        end
      elsif self.container_type.well_count < 96
        raise RuntimeError.new "Cannot return quadrant for a container type with less than 96 wells."
      end
      if ![0, 1, 2, 3].include? quad
        raise AutoprotocolError.new "Invalid quadrant entered for the specified plate type."
      end

      start_well = [0, 1, 24, 25]
      wells = []

      (start_well[quad]..384).step(48).each do |row_offset|
        (0..24).step(2).each do |col_offset|
          wells.push(row_offset + col_offset)
        end
      end
      WellGroup.new well.collect{ |w| self.well(w)}
    end

    def to_s
      "Container(#{self.name.to_s})"
    end
  end
end
