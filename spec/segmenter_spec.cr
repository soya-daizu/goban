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
end
