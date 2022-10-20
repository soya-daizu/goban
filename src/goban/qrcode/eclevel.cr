struct Goban::QRCode
  # Error correction level of the QR Code.
  # QR Code symbols include redundant bits based on the selected error
  # correction level, so that even if some part the symbol is not readable,
  # the decoder can recover the loss for up to:
  #
  # - 7% for `Low`
  # - 15% for `Medium`
  # - 25% for `Quartile`
  # - 30% for `High`
  #
  # Note that choosing a higher error correction level requires more redundant
  # bits, meaning that the resulting QR Code symbol can get larger.
  enum ECLevel : UInt8
    Low      = 0
    Medium   = 1
    Quartile = 2
    High     = 3

    # Returns data bits that represent its error correction level.
    protected def format_bits
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
