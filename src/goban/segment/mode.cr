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
        raise "Unsupported mode"
      end
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
        raise "Unsupported mode"
      end

      index = {1..9, 10..26, 27..40}.index! { |range| range.includes?(ver) }
      values[index]
    end

      else
      end
    end
  end
end
