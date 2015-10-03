module Autoprotocol
  module Util
    # Convert a Unit or volume string into its equivalent in microliters.
    #
    # === Parameters
    #
    # * vol : Unit, str
    #         A volume string or Unit with the unit "nanoliter" or "milliliter"
    def convert_to_ul(vol)
      v = Unit.fromstring(vol)
      if v.unit == "nanoliter"
        v = Unit(v.value/1000, "microliter")
      elsif v.unit == "milliliter"
        v = Unit(v.value*1000, "microliter")
      elsif v.unit == "microliter"
        return v
      else
        raise ValueError, "The unit you're trign to convert to microliters is invalid"
      end
      v
    end

    # Convert a 384-well plate quadrant well index into its corresponding
    # integer form.
    #
    # "A1" -> 0
    # "A2" -> 1
    # "B1" -> 2
    # "B2" -> 3
    #
    # === Parameters
    #
    # * q : int, str
    #       A string or integer representing a well index that corresponds to a
    #       quadrant on a 384-well plate.
    def quad_ind_to_num(q)
      if q.is_a? String
        q = q.lower()
      end
      if ["a1", 0].include? q
        return 0
      elsif ["a2", 1].include? q
        return 1
      elsif ["b1", 24].include? q
        return 2
      elsif ["b2", 25].include? q
        return 3
      else
        raise ValueError.new "Invalid quadrant index."
      end
    end

    # Convert a 384-well plate quadrant integer into its corresponding well index.
    #
    # 0 -> "A1" or 0
    # 1 -> "A2" or 1
    # 2 -> "B1" or 24
    # 3 -> "B2" or 25
    #
    # === Parameters
    #
    # * q : int
    #       An integer representing a quadrant number of a 384-well plate.
    # * human : bool, optional
    #       Return the corresponding well index in human readable form instead of
    #       as an integer if True.
    def quad_num_to_ind(q, human=false)
      if q == 0
        if human
          return "A1"
        else
          return 0
        end
      elsif q == 1
        if human
          return "A2"
        else
          return 1
        end
      elsif q == 2
        if human
          return "B1"
        else
          return 24
        end
      elsif q == 3
        if human
          return "B2"
        else
          return 25
        end
      else
        raise ValueError.new "Invalid quadrant number."
      end
    end

  end
end
