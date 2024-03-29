struct Goban::Segment
  # Represents a encoding mode of a data segment.
  enum Mode : UInt8
    ECI
    Numeric
    Alphanumeric
    Byte
    Kanji
    StructuredAppend
    Undefined        = UInt8::MAX

    protected def self.from_bits(bits : Int, ver : QR::Version)
      case bits
      when 0b0001
        Numeric
      when 0b0010
        Alphanumeric
      when 0b0100
        Byte
      when 0b1000
        Kanji
      else
        raise InputError.new("Unknown encoding mode")
      end
    end

    protected def self.from_bits(bits : Int, ver : MQR::Version)
      case bits
      when 0b000
        Numeric
      when 0b001
        raise InputError.new("Invalid encoding mode") if ver < 2
        Alphanumeric
      when 0b010
        raise InputError.new("Invalid encoding mode") if ver < 3
        Byte
      when 0b011
        raise InputError.new("Invalid encoding mode") if ver < 3
        Kanji
      else
        raise InputError.new("Unknown encoding mode")
      end
    end

    protected def self.from_bits(bits : Int, ver : RMQR::Version)
      case bits
      when 0b001
        Numeric
      when 0b010
        Alphanumeric
      when 0b011
        Byte
      when 0b100
        Kanji
      else
        raise InputError.new("Unknown encoding mode")
      end
    end

    protected def indicator(ver : QR::Version)
      case self
      when Numeric
        0b0001
      when Alphanumeric
        0b0010
      when Byte
        0b0100
      when Kanji
        0b1000
      else
        raise InternalError.new("Unknown encoding mode")
      end
    end

    protected def indicator(ver : MQR::Version)
      case self
      when Numeric
        values = {0b0, 0b0, 0b00, 0b000}
      when Alphanumeric
        values = {nil, 0b1, 0b01, 0b001}
      when Byte
        values = {nil, nil, 0b10, 0b010}
      when Kanji
        values = {nil, nil, 0b11, 0b011}
      else
        raise InternalError.new("Unknown encoding mode")
      end

      values[ver.to_i - 1]
    end

    protected def indicator(ver : RMQR::Version)
      case self
      when Numeric
        0b001
      when Alphanumeric
        0b010
      when Byte
        0b011
      when Kanji
        0b100
      else
        raise InternalError.new("Unknown encoding mode")
      end
    end

    # Number of the character count indicator bits for this mode.
    protected def cci_bits_count(ver : QR::Version)
      case self
      when Numeric
        counts = {10, 12, 14}
      when Alphanumeric
        counts = {9, 11, 13}
      when Byte
        counts = {8, 16, 16}
      when Kanji
        counts = {8, 10, 12}
      else
        raise InternalError.new("Unknown encoding mode")
      end

      index = {1..9, 10..26, 27..40}.index! { |range| ver.in?(range) }
      counts[index]
    end

    # Number of the character count indicator bits for this mode.
    protected def cci_bits_count(ver : MQR::Version)
      case self
      when Numeric
        counts = {3, 4, 5, 6}
      when Alphanumeric
        counts = {nil, 3, 4, 5}
      when Byte
        counts = {nil, nil, 4, 5}
      when Kanji
        counts = {nil, nil, 3, 4}
      else
        raise InternalError.new("Unknown encoding mode")
      end

      counts[ver.to_i - 1]
    end

    # Number of the character count indicator bits for this mode.
    protected def cci_bits_count(ver : RMQR::Version)
      case self
      when Numeric
        counts = {4, 5, 6, 7, 7, 5, 6, 7, 7, 8, 4, 6, 7, 7, 8, 8, 5, 6, 7, 7, 8, 8, 7, 7, 8, 8, 9, 7, 8, 8, 8, 9}
      when Alphanumeric
        counts = {3, 5, 5, 6, 6, 5, 5, 6, 6, 7, 4, 5, 6, 6, 7, 7, 5, 6, 6, 7, 7, 8, 6, 7, 7, 7, 8, 6, 7, 7, 8, 8}
      when Byte
        counts = {3, 4, 5, 5, 6, 4, 5, 5, 6, 6, 3, 5, 5, 6, 6, 7, 4, 5, 6, 6, 7, 7, 6, 6, 7, 7, 7, 6, 6, 7, 7, 8}
      when Kanji
        counts = {2, 3, 4, 5, 5, 3, 4, 5, 5, 6, 2, 4, 5, 5, 6, 6, 3, 5, 5, 6, 6, 7, 5, 5, 6, 6, 7, 5, 6, 6, 6, 7}
      else
        raise InternalError.new("Unknown encoding mode")
      end

      counts[ver.to_i]
    end
  end
end
