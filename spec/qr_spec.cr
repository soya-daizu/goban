require "./spec_helper"

module Goban
  describe QR do
    describe ".encode_string" do
      qr = QR.encode_string(SAMPLE_STR, ECC::Level::Medium)

      it "reports correct version" do
        qr.version.value.should eq(2)
      end

      it "reports correct ec level" do
        qr.ecl.should eq(ECC::Level::Medium)
      end

      it "encodes properly" do
        rows = convert_canvas_to_text(qr.canvas)
        rows.should eq(SAMPLE_RESULT_MODS_QR)
      end

      it "raises if text is too long" do
        long_str = String.build do |io|
          7090.times { io << '0' } # Numeric mode can contain upto 7089 characters
        end

        expect_raises(Exception, "Text too long") do
          QR.encode_string(long_str, ECC::Level::Low)
        end
      end
    end

    describe ".encode_segments" do
      qr = QR.encode_segments(SAMPLE_SEGS, ECC::Level::Medium, 2)

      it "reports correct version" do
        qr.version.value.should eq(2)
      end

      it "reports correct ec level" do
        qr.ecl.should eq(ECC::Level::Medium)
      end

      it "encodes properly" do
        rows = convert_canvas_to_text(qr.canvas)
        rows.should eq(SAMPLE_RESULT_MODS_QR)
      end
    end

    describe ".decode" do
      canvas = convert_text_to_canvas(SAMPLE_RESULT_MODS_QR)

      it "decodes properly" do
        segments = QR.decode(canvas).segments
        segments.should eq(SAMPLE_SEGS)
      end
    end

    describe ".draw_data_codewords" do
      it "fills codewords properly" do
        version = QR::Version.new(1)
        canvas = Canvas(UInt8).new(version.symbol_size, version.symbol_size, 0)
        canvas[8, 8, 7, 7] = 0xc0

        codewords = Slice(UInt8).new(21 ** 2 // 8, 154)
        QR::Encoder.draw_codewords(canvas, codewords)

        rows = convert_canvas_to_text(canvas)
        rows.should eq(CODEWORDS_FILL_MODS_QR)
      end
    end

    describe ".apply_best_mask" do
      it "applies best mask" do
        version = QR::Version.new(1)
        canvas = Canvas(UInt8).new(version.symbol_size, version.symbol_size, 0)
        canvas.data.map_with_index! { |_, idx| idx.odd?.to_unsafe.to_u8 }

        QR::Encoder.apply_best_mask(canvas, ECC::Level::Low)[0].value.should eq(2)
      end
    end
  end
end
