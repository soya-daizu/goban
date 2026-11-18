require "./spec_helper"

module Goban
  describe QR::Encoder do
    describe ".determine_version_and_segments" do
      it "optimizes all-numeric string" do
        segments, version = QR::Encoder.determine_version_and_segments(ALL_NUMERIC_STR, ECC::Level::Medium)
        segments.should eq(ALL_NUMERIC_SEGS)
        version.should eq(1)
      end

      it "optimizes all-alphanumeric string" do
        segments, version = QR::Encoder.determine_version_and_segments(ALL_ALPHANUMERIC_STR, ECC::Level::Medium)
        segments.should eq(ALL_ALPHANUMERIC_SEGS)
        version.should eq(1)
      end

      it "optimizes all-byte string" do
        segments, version = QR::Encoder.determine_version_and_segments(ALL_BYTE_STR, ECC::Level::Medium)
        segments.should eq(ALL_BYTE_SEGS)
        version.should eq(1)
      end

      it "optimizes all-kanji string" do
        segments, version = QR::Encoder.determine_version_and_segments(ALL_KANJI_STR, ECC::Level::Medium)
        segments.should eq(ALL_KANJI_SEGS)
        version.should eq(1)
      end

      it "optimizes [numeric/alphanumeric] string to [alphanumeric]" do
        segments, version = QR::Encoder.determine_version_and_segments(NUMERIC_ALPHANUMERIC_1_STR, ECC::Level::Medium)
        segments.should eq(NUMERIC_ALPHANUMERIC_1_SEGS)
        version.should eq(1)
      end

      it "optimizes [numeric/alphanumeric] string to [numeric/alphanumeric]" do
        segments, version = QR::Encoder.determine_version_and_segments(NUMERIC_ALPHANUMERIC_2_STR, ECC::Level::Medium)
        segments.should eq(NUMERIC_ALPHANUMERIC_2_SEGS)
        version.should eq(1)
      end

      it "optimizes [numeric/byte] string to [byte]" do
        segments, version = QR::Encoder.determine_version_and_segments(NUMERIC_BYTE_1_STR, ECC::Level::Medium)
        segments.should eq(NUMERIC_BYTE_1_SEGS)
        version.should eq(1)
      end

      it "optimizes [numeric/byte] string to [numeric/byte]" do
        segments, version = QR::Encoder.determine_version_and_segments(NUMERIC_BYTE_2_STR, ECC::Level::Medium)
        segments.should eq(NUMERIC_BYTE_2_SEGS)
        version.should eq(1)
      end

      it "optimizes [alphanumeric/byte] string to [byte]" do
        segments, version = QR::Encoder.determine_version_and_segments(ALPHANUMERIC_BYTE_1_STR, ECC::Level::Medium)
        segments.should eq(ALPHANUMERIC_BYTE_1_SEGS)
        version.should eq(1)
      end

      it "optimizes [alphanumeric/byte] string to [alphanumeric/byte]" do
        segments, version = QR::Encoder.determine_version_and_segments(ALPHANUMERIC_BYTE_2_STR, ECC::Level::Medium)
        segments.should eq(ALPHANUMERIC_BYTE_2_SEGS)
        version.should eq(1)
      end

      it "optimizes [kanji/byte/alphanumeric] string" do
        segments, version = QR::Encoder.determine_version_and_segments(SAMPLE_STR, ECC::Level::Medium)
        segments.should eq(SAMPLE_SEGS)
        version.should eq(2)
      end
    end
  end

  describe Segment::Segmenter::Analysis do
    it "splits segments at the character boundaries of multibyte text" do
      analysis = Segment::Segmenter::Analysis.new("漢字abc0123456789漢字")
      analysis.byte_offsets.to_a.should eq([0, 3, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 22, 25])
      analysis.segments_for(QR::Version.new(1)).map { |s| {s.mode, s.text} }.should eq([
        {Segment::Mode::Kanji, "漢字"},
        {Segment::Mode::Byte, "abc"},
        {Segment::Mode::Numeric, "0123456789"},
        {Segment::Mode::Kanji, "漢字"},
      ])
    end

    it "keeps the original bytes of invalid UTF-8 sequences" do
      text = String.new(Bytes[0x41, 0xff, 0x42])
      segments = Segment::Segmenter::Analysis.new(text).segments_for(QR::Version.new(1))
      segments.sum(&.text.bytesize).should eq(3)
      segments.map(&.text).join.to_slice.should eq(text.to_slice)
    end

    it "computes the lower bound of the data bits" do
      # Kanji 13 * 2 + Byte 8 * 3 + Numeric 10 / 3 * 10 (rounded up)
      Segment::Segmenter::Analysis.new("漢字abc0123456789").min_data_bits.should eq(26 + 24 + 34)
    end

    it "counts the actual bytes of invalid UTF-8 sequences in the lower bound" do
      # Each invalid byte is one byte, not the 3 bytes of the replacement character
      text = String.new(Bytes[0x41, 0xff, 0x42, 0xe3, 0x81])
      Segment::Segmenter::Analysis.new(text).min_data_bits.should be <= text.bytesize * 8

      _, version = MQR::Encoder.determine_version_and_segments(text, ECC::Level::Medium)
      version.should eq(3)
    end

    it "reuses the segments for versions with the same indicator lengths" do
      analysis = Segment::Segmenter::Analysis.new("HELLO 123")
      analysis.segments_for(QR::Version.new(1)).should be(analysis.segments_for(QR::Version.new(9)))
      analysis.segments_for(QR::Version.new(9)).should_not be(analysis.segments_for(QR::Version.new(10)))
    end
  end
end
