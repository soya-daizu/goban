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

    protected def indicator(ver : QR::Version)
      case self
      when Numeric
        {0b0001, 4}
      when Alphanumeric
        {0b0010, 4}
      when Byte
        {0b0100, 4}
      when Kanji
        {0b1000, 4}
      else
        raise "Unknown encoding mode"
      end
    end

    protected def indicator(ver : MQR::Version)
      case self
      when Numeric
        values = {nil, 0b0, 0b00, 0b000}
      when Alphanumeric
        values = {nil, 0b1, 0b01, 0b001}
      when Byte
        values = {nil, nil, 0b10, 0b010}
      when Kanji
        values = {nil, nil, 0b11, 0b011}
      else
        raise "Unknown encoding mode"
      end

      indicator = values[ver.to_i - 1]
      raise "Unsupported encoding mode" unless indicator
      {indicator, ver.to_i - 1}
    end

    # Number of the character count indicator bits for this mode.
    protected def cci_bits_count(ver : QR::Version)
      case self
      when Numeric
        values = {10, 12, 14}
      when Alphanumeric
        values = {9, 11, 13}
      when Byte
        values = {8, 16, 16}
      when Kanji
        values = {8, 10, 12}
      else
        raise "Unknown encoding mode"
      end

      index = {1..9, 10..26, 27..40}.index! { |range| range.includes?(ver) }
      values[index]
    end

    # Number of the character count indicator bits for this mode.
    protected def cci_bits_count(ver : MQR::Version)
      case self
      when Numeric
        values = {3, 4, 5, 6}
      when Alphanumeric
        values = {nil, 3, 4, 5}
      when Byte
        values = {nil, nil, 4, 5}
      when Kanji
        values = {nil, nil, 3, 4}
      else
        raise "Unknown encoding mode"
      end

      count = values[ver.to_i - 1]
      raise "Unsupported encoding mode" unless count
      count
    end
  end
end
