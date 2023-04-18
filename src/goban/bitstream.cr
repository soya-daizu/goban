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
    # Current tail index of the writer. This increases as more bits are written.
    property write_pos = 0
    # Current tail index of the reader. This increases as more bits are read.
    property read_pos = 0
    # Whether this bit stream is read-only.
    getter read_only : Bool

    PAD0 = 0b1110_1100
    PAD1 = 0b0001_0001

    def initialize(size : Int)
      raise "Negative bit stream size: #{size}" if size < 0
      @size = size.to_i
      @bits = Pointer(UInt8).malloc(malloc_size, 0)
      @read_only = false
    end

    def initialize(bytes : Slice(UInt8))
      @size = bytes.size * 8
      @bits = bytes.to_unsafe
      @read_only = true
    end

    protected def append_segment_bits(segment : Segment, version : AbstractQR::Version)
      indicator = segment.mode.indicator(version)
      indicator_length = version.mode_indicator_length

      cci_bits = segment.char_count
      cci_bits_count = segment.mode.cci_bits_count(version)

      raise "Invalid segment" if !cci_bits_count
      raise "Text too long" if indicator_length + cci_bits_count + segment.bit_size > size

      push_bits(indicator, indicator_length)
      push_bits(cci_bits, cci_bits_count)

      segment.produce_bits.each do |val, len|
        push_bits(val, len)
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
      terminator_bits_size = Math.min(base, cap_bits - @write_pos)
      push_bits(0, terminator_bits_size)
    end

    protected def append_padding_bits(version : AbstractQR::Version)
      # In version M1 and M3, we need to use shorter padding bits 0000,
      # but since the data stream is already filled with zeros, there's nothing more to append
      short_pad = typeof(version) == MQR::Version && (version == 1 || version == 3)
      if short_pad
        # Version M1 and M3 have a shorter last codeword of 4 bits
        # (for a total of 8 bits including the padding bits 0000),
        # so we are shifting them to the right by four here
        @bits[@write_pos - 1] >>= 4
        return
      end

      while @write_pos % 8 != 0
        self.push(false)
      end

      while @write_pos < @size
        push_bits(PAD0, 8)
        push_bits(PAD1, 8) if @write_pos < @size
      end
    end

    protected def push_bits(val : Int?, len : Int?)
      return if !val || !len
      return if len == 0

      raise "Too many bits to append" unless (0..31).includes?(len) && val >> len == 0
      (0...len).reverse_each do |i|
        self.push((val >> i) & 1 != 0)
      end
    end

    protected def read_bits(len : Int)
      raise "Too many bits to read" unless (0..31).includes?(len) && @read_pos + len <= @size

      result = 0_u32
      len.times do |i|
        bit = self[@read_pos] ? 1 : 0
        result = (result << 1) | bit
        @read_pos += 1
      end

      result
    end

    protected def unsafe_fetch(index : Int)
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
      raise "Can't write to a read-only bit stream" if read_only
      self[@write_pos] = value
      @write_pos += 1

      value
    end

    protected def to_bytes
      Slice(UInt8).new(@bits, malloc_size, read_only: true)
    end

    def inspect(io : IO)
      io << "Goban::BitStream(@write_pos=" << @write_pos
      io << ", @read_pos=" << @read_pos
      io << ", @bits=["
      idx = 0
      self.each_slice(4) do |bits|
        io << ' ' unless idx == 0
        bits.each do |bit|
          io << '\'' if idx == @write_pos || idx == @read_pos
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

    private def malloc_size
      (@size + 7) // 8
    end
  end
end
