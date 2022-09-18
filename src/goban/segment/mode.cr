struct Goban::Segment
  enum Mode : UInt8
    ECI              = 0b0111
    Numeric          = 0b0001
    Alphanumeric     = 0b0010
    Byte             = 0b0100
    Kanji            = 0b1000
    StructuredAppend = 0b0011
    Invalid          = UInt8::MAX

    # Number of character count indicator bits for this mode
    def cci_bits_size(ver : QRCode::Version)
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
        raise "Incompatible mode"
      end

      if (1..9).includes?(ver)
        values[0]
      elsif (10..26).includes?(ver)
        values[1]
      elsif (27..40).includes?(ver)
        values[2]
      else
        raise "Invalid version object"
      end
    end
  end
end
