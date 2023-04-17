require "./spec_helper"

module Goban
  describe Segment do
    describe ".numeric" do
      segment = Segment.numeric(ALL_NUMERIC_STR)
      result = segment.produce_bits.to_a

      it "reports correct character count" do
        segment.char_count.should eq(ALL_NUMERIC_STR.bytesize)
      end

      it "produces bits properly" do
        result.should eq([
          {12, 10},
          {345, 10},
          {678, 10},
          {9, 4},
        ])
      end

      it "can reproduce segment from produced bits" do
        bit_stream = BitStream.new(result.sum(&.[1]))
        result.each do |val, len|
          bit_stream.push_bits(val, len)
        end
        reproduced = Segment.new(Segment::Mode::Numeric, segment.text.size, bit_stream)
        reproduced.should eq(segment)
      end
    end

    describe ".alphanumeric" do
      segment = Segment.alphanumeric(ALL_ALPHANUMERIC_STR)
      result = segment.produce_bits.to_a

      it "reports correct character count" do
        segment.char_count.should eq(ALL_ALPHANUMERIC_STR.bytesize)
      end

      it "produces bits properly" do
        result.should eq([
          {461, 11},
          {553, 11},
          {645, 11},
          {16, 6},
        ])
      end

      it "can reproduce segment from produced bits" do
        bit_stream = BitStream.new(result.sum(&.[1]))
        result.each do |val, len|
          bit_stream.push_bits(val, len)
        end
        reproduced = Segment.new(Segment::Mode::Alphanumeric, segment.text.size, bit_stream)
        reproduced.should eq(segment)
      end
    end

    describe ".byte" do
      segment = Segment.byte(ALL_BYTE_STR)
      result = segment.produce_bits.to_a

      it "reports correct character count" do
        segment.char_count.should eq(ALL_BYTE_STR.bytesize)
      end

      it "produces bits properly" do
        result.should eq([
          {97, 8},
          {208, 8},
          {137, 8},
          {236, 8},
          {156, 8},
          {135, 8},
          {240, 8},
          {159, 8},
          {152, 8},
          {177, 8},
        ])
      end

      it "can reproduce segment from produced bits" do
        bit_stream = BitStream.new(result.sum(&.[1]))
        result.each do |val, len|
          bit_stream.push_bits(val, len)
        end
        reproduced = Segment.new(Segment::Mode::Byte, segment.text.bytesize, bit_stream)
        reproduced.should eq(segment)
      end
    end

    describe ".kanji" do
      segment = Segment.kanji(ALL_KANJI_STR)
      result = segment.produce_bits.to_a

      it "reports correct character count" do
        segment.char_count.should eq(ALL_KANJI_STR.size)
      end

      it "produces bits properly" do
        result.should eq([
          {2949, 13},
          {2991, 13},
          {332, 13},
          {4098, 13},
          {2775, 13},
        ])
      end

      it "can reproduce segment from produced bits" do
        bit_stream = BitStream.new(result.sum(&.[1]))
        result.each do |val, len|
          bit_stream.push_bits(val, len)
        end
        reproduced = Segment.new(Segment::Mode::Kanji, segment.text.size, bit_stream)
        reproduced.should eq(segment)
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
