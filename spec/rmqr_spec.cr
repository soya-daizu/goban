require "./spec_helper"

module Goban
  describe RMQR do
    describe ".encode_string" do
      qr = RMQR.encode_string(SAMPLE_STR_2, ECC::Level::Medium)

      it "reports correct version" do
        qr.version.value.should eq(RMQR::VersionValue::R13x27)
      end

      it "reports correct ec level" do
        qr.ecl.should eq(ECC::Level::Medium)
      end

      it "encodes properly" do
        rows = convert_canvas(qr.canvas)
        rows.should eq(SAMPLE_RESULT_MODS_RMQR)
      end

      it "raises if text is too long" do
        long_str = String.build do |io|
          362.times { io << '0' } # Numeric mode can contain upto 361 characters
        end

        expect_raises(Exception, "Text too long") do
          RMQR.encode_string(long_str, ECC::Level::Medium)
        end
      end
    end

    describe ".encode_segments" do
      qr = RMQR.encode_segments(SAMPLE_SEGS_2, ECC::Level::Medium, RMQR::VersionValue::R13x27)

      it "reports correct version" do
        qr.version.value.should eq(RMQR::VersionValue::R13x27)
      end

      it "reports correct ec level" do
        qr.ecl.should eq(ECC::Level::Medium)
      end

      it "encodes properly" do
        rows = convert_canvas(qr.canvas)
        rows.should eq(SAMPLE_RESULT_MODS_RMQR)
      end
    end
  end
end

