struct Goban::QRCode
  enum ECLevel : UInt8
    Low      = 0
    Medium   = 1
    Quartile = 2
    High     = 3

    def format_bits
      case self
      when Low
        0b01_u8
      when Medium
        0b00_u8
      when Quartile
        0b11_u8
      when High
        0b10_u8
      else
        raise "Invalid EC level"
      end
    end
  end
end
