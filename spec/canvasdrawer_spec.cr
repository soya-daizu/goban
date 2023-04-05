require "./spec_helper"

module Goban
  describe QR::CanvasDrawer do
    describe "#draw_function_patterns" do
      it "draws all function patterns" do
        version = QR::Version.new(7)
        canvas = Matrix(UInt8).new(version.symbol_size, version.symbol_size, 0)
        QR::CanvasDrawer.draw_function_patterns(canvas, version)
        canvas.normalize

        rows = convert_canvas(canvas)
        rows.should eq(FUNCTION_PATTERN_MODS_QR)
      end
    end

    describe "#draw_data_codewords" do
      it "fills codewords properly" do
        version = QR::Version.new(1)
        canvas = Matrix(UInt8).new(version.symbol_size, version.symbol_size, 0)
        canvas[8, 8, 7, 7] = 0xc0

        codewords = Slice(UInt8).new(21 ** 2 // 8, 154)
        QR::CanvasDrawer.draw_data_codewords(canvas, codewords)

        rows = convert_canvas(canvas)
        rows.should eq(CODEWORDS_FILL_MODS_QR)
      end
    end

    describe "#apply_best_mask" do
      it "applies best mask" do
        version = QR::Version.new(1)
        canvas = Matrix(UInt8).new(version.symbol_size, version.symbol_size, 0)
        canvas.data.map_with_index! { |_, idx| idx.odd?.to_unsafe.to_u8 }

        QR::CanvasDrawer.apply_best_mask(canvas, ECC::Level::Low)[0].value.should eq(2)
      end
    end
  end

  describe MQR::CanvasDrawer do
    describe "#draw_function_patterns" do
      it "draws all function patterns" do
        version = MQR::Version.new(1)
        canvas = Matrix(UInt8).new(version.symbol_size, version.symbol_size, 0)
        MQR::CanvasDrawer.draw_function_patterns(canvas)
        canvas.normalize

        rows = convert_canvas(canvas)
        rows.should eq(FUNCTION_PATTERN_MODS_MQR)
      end
    end

    describe "#draw_data_codewords" do
      it "fills codewords properly" do
        version = MQR::Version.new(1)
        canvas = Matrix(UInt8).new(version.symbol_size, version.symbol_size, 0)
        canvas[3, 3, 3, 3] = 0xc0

        codewords = Slice(UInt8).new(11 ** 2 // 8, 154)
        MQR::CanvasDrawer.draw_data_codewords(canvas, codewords, version, ECC::Level::Low)
        canvas.normalize

        rows = convert_canvas(canvas)
        rows.should eq(CODEWORDS_FILL_MODS_MQR)
      end
    end

    describe "#apply_best_mask" do
      it "applies best mask" do
        version = MQR::Version.new(1)
        canvas = Matrix(UInt8).new(version.symbol_size, version.symbol_size, 0)
        canvas.data.map_with_index! { |_, idx| idx.odd?.to_unsafe.to_u8 }

        MQR::CanvasDrawer.apply_best_mask(canvas, version, ECC::Level::Low)[0].value.should eq(3)
      end
    end
  end
end
