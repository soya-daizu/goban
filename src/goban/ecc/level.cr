module Goban::ECC
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
  enum Level : UInt8
    Low      = 0b01
    Medium   = 0b00
    Quartile = 0b11
    High     = 0b10
  end
end
