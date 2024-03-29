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
        rows = convert_canvas_to_text(qr.canvas)
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
        rows = convert_canvas_to_text(qr.canvas)
        rows.should eq(SAMPLE_RESULT_MODS_RMQR)
      end
    end

    describe ".decode" do
      canvas = convert_text_to_canvas(SAMPLE_RESULT_MODS_RMQR)

      it "decodes properly" do
        segments = RMQR.decode(canvas).segments
        segments.should eq(SAMPLE_SEGS_2)
      end
    end

    # describe ".draw_data_codewords" do
    #  it "fills codewords properly" do
    #    version = MQR::Version.new(1)
    #    canvas = Canvas(UInt8).new(version.symbol_size, version.symbol_size, 0)
    #    canvas[3, 3, 3, 3] = 0xc0

    #    codewords = Slice(UInt8).new(11 ** 2 // 8, 154)
    #    MQR::Encoder.draw_codewords(canvas, codewords, version, ECC::Level::Low)

    #    rows = convert_canvas_to_text(canvas)
    #    rows.should eq(CODEWORDS_FILL_MODS_MQR)
    #  end
    # end

    # describe ".apply_best_mask" do
    #  it "applies best mask" do
    #    version = MQR::Version.new(1)
    #    canvas = Canvas(UInt8).new(version.symbol_size, version.symbol_size, 0)
    #    canvas.data.map_with_index! { |_, idx| idx.odd?.to_unsafe.to_u8 }

    #    MQR::Encoder.apply_best_mask(canvas, version, ECC::Level::Low)[0].value.should eq(3)
    #  end
    # end
  end
end
