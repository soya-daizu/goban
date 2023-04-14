require "./spec_helper"

module Goban
  describe Segment do
    describe ".numeric" do
      segment = Segment.numeric(ALL_NUMERIC_STR)

      it "reports correct character count" do
        segment.char_count.should eq(ALL_NUMERIC_STR.bytesize)
      end

      it "encodes properly" do
        bit_stream = BitStream.new(segment.bit_size)
        segment.produce_bits do |val, len|
          bit_stream.push_bits(val, len)
        end
        bit_str = convert_bit_stream(bit_stream)
        bit_str.should eq("0000001100010101100110101001101001")
      end
    end

    describe ".alphanumeric" do
      segment = Segment.alphanumeric(ALL_ALPHANUMERIC_STR)

      it "reports correct character count" do
        segment.char_count.should eq(ALL_ALPHANUMERIC_STR.bytesize)
      end

      it "encodes properly" do
        bit_stream = BitStream.new(segment.bit_size)
        segment.produce_bits do |val, len|
          bit_stream.push_bits(val, len)
        end
        bit_str = convert_bit_stream(bit_stream)
        bit_str.should eq("001110011010100010100101010000101")
      end
    end

    describe ".byte" do
      segment = Segment.byte(ALL_BYTE_STR)

      it "reports correct character count" do
        segment.char_count.should eq(ALL_BYTE_STR.bytesize)
      end

      it "encodes properly" do
        bit_stream = BitStream.new(segment.bit_size)
        segment.produce_bits do |val, len|
          bit_stream.push_bits(val, len)
        end
        bit_str = convert_bit_stream(bit_stream)
        bit_str.should eq("01100001110100001000100111101100100111001000011111110000100111111001100010110001")
      end
    end

    describe ".kanji" do
      segment = Segment.kanji(ALL_KANJI_STR)

      it "reports correct character count" do
        segment.char_count.should eq(ALL_KANJI_STR.size)
      end

      it "encodes properly" do
        bit_stream = BitStream.new(segment.bit_size)
        segment.produce_bits do |val, len|
          bit_stream.push_bits(val, len)
        end
        bit_str = convert_bit_stream(bit_stream)
        bit_str.should eq("01011100001010101110101111000010100110010000000000100101011010111")
      end
    end

    describe ".count_total_bits" do
      segments = SAMPLE_SEGS

      it "reports correct bit count" do
        count = Segment.count_total_bits(segments, QR::Version.new(2))
        count.should eq(191)
      end

      it "raises if segment is too long" do
        long_str = String.build do |io|
          256.times { io << 'あ' } # Kanji mode segment can contain upto 255 characters
        end

        expect_raises(Exception, "Segment too long") do
          Segment.count_total_bits([Segment.kanji(long_str)], QR::Version.new(1))
        end
      end
    end
  end
end
