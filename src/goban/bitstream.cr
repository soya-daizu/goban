module Goban
  # An array data structure that holds bits.
  # Based on the `BitArray` object of the standard library.
  struct BitStream
    include Indexable::Mutable(Bool)
    include Comparable(BitStream)

    # Pointer to the underlying UInt8 representation.
    getter bits : Pointer(UInt8)
    # Size of the array.
    getter size : Int32
    # Current tail index of the array. This increases as
    # more bits are added to itself.
    getter tail_idx = 0

    PAD0 = 0b1110_1100
    PAD1 = 0b0001_0001

    def initialize(size : Int)
      raise "Negative bit stream size: #{size}" if size < 0
      @size = size.to_i
      @bits = Pointer(UInt8).malloc(malloc_size, 0)
    end

    protected def append_segment_bits(segment : Segment, version : AbstractQR::Version)
      indicator = segment.mode.indicator(version)
      indicator_length = version.mode_indicator_length

      cci_bits = segment.char_count
      cci_bits_count = segment.mode.cci_bits_count(version)

      raise "Invalid segment" if !cci_bits_count
      raise "Text too long" if indicator_length + cci_bits_count + segment.bit_stream.size > size

      push_bits(indicator, indicator_length)
      push_bits(cci_bits, cci_bits_count)
      append_bit_stream(segment.bit_stream)
    end

    private def append_bit_stream(bs : BitStream)
      bs.each do |bit|
        self.push(bit)
      end
    end

    protected def append_terminator_bits(version : AbstractQR::Version, ecl : ECC::Level)
      cap_bits = version.max_data_bits(ecl)
      case version
      when QR::Version
        base = 4
      when MQR::Version
        base = 3 + (version.to_i - 1) * 2
      when RMQR::Version
        base = 3
      else
        raise "Invalid QR version"
      end
      terminator_bits_size = Math.min(base, cap_bits - @tail_idx)
      push_bits(0, terminator_bits_size)
    end

    protected def append_padding_bits(version : AbstractQR::Version)
      # In the version M1 and M3, we need to use the shorter padding bits 0000 to fill
      # the rest of the data stream, but the data stream is already filled with zeros,
      # so there's nothing more to do here
      short_pad = typeof(version) == MQR::Version && (version == 1 || version == 3)
      return if short_pad

      while @tail_idx % 8 != 0
        self.push(false)
      end

      while @tail_idx < @size
        push_bits(PAD0, 8)
        push_bits(PAD1, 8) if @write_pos < @size
      end
    end

    protected def push_bits(val : Int?, len : Int?)
      return if !val || !len
      return if len == 0

      raise "Value out of range" unless (0..31).includes?(len) && val >> len == 0
      (0..len - 1).reverse_each do |i|
        self.push((val >> i).to_u8! & 1 != 0)
      end
    end

    protected def unsafe_fetch(index : Int) : Bool
      bit_idx, sub_idx = index.divmod(8)
      sub_idx = 7 - sub_idx
      (@bits[bit_idx] & (1 << sub_idx)) > 0
    end

    protected def unsafe_put(index : Int, value : Bool)
      bit_idx, sub_idx = index.divmod(8)
      sub_idx = 7 - sub_idx
      if value
        @bits[bit_idx] |= 1 << sub_idx
      else
        @bits[bit_idx] &= ~(1 << sub_idx)
      end
    end

    # Adds a value to the current tail of the array.
    private def push(value : Bool)
      bit_idx, sub_idx = bit_idx_and_sub_idx(@tail_idx)
      if value
        @bits[bit_idx] |= 1 << sub_idx
      else
        @bits[bit_idx] &= ~(1 << sub_idx)
      end
      @tail_idx += 1

      value
    end

    protected def to_bytes
      @bits.to_slice(malloc_size)
    end

    def inspect(io : IO)
      io << "Goban::BitStream(@tail_idx=" << @tail_idx
      io << ", @bits=["
      idx = 0
      self.each_slice(4) do |bits|
        io << ' ' unless idx == 0
        bits.each do |bit|
          io << '\'' if idx == @tail_idx
          io << (bit ? '1' : '0')
          idx += 1
        end
      end
      io << "])"
    end

    def <=>(other : BitStream)
      min_size = Math.min(size, other.size)
      (0...min_size).each do |i|
        return nil if self[i] != other[i]
      end
      size <=> other.size
    end

    private def bit_idx_and_sub_idx(idx)
      bit_idx_and_sub_idx(idx) { raise IndexError.new }
    end

    private def bit_idx_and_sub_idx(idx)
      idx = check_index_out_of_bounds(idx) do
        return yield
      end
      bit_idx, sub_idx = idx.divmod(8)
      {bit_idx, 7 - sub_idx}
    end

    private def malloc_size
      (@size + 7) // 8
    end
  end
end
