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

  # :nodoc:
  # Expands to the value for the level `ecl` in the named tuple `table` keyed
  # by the level names, such as `{Low: 1, Medium: 2, Quartile: 3, High: 4}`.
  # This is the same as `table[ecl.to_s]` but the key is resolved at compile
  # time, and the table is accessed in place instead of being passed around.
  # The table must have the keys for all the levels.
  macro lookup(table, ecl)
    case {{ecl}}
    in .low?      then {{table}}[:Low]
    in .medium?   then {{table}}[:Medium]
    in .quartile? then {{table}}[:Quartile]
    in .high?     then {{table}}[:High]
    end
  end
end
