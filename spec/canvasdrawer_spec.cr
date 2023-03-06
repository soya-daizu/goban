require "./spec_helper"

module Goban
  struct QR::CanvasDrawer
    def reserve_modules_for_test
      @canvas[8, 8, 7, 7] = 0xc0
    end
  end

  struct MQR::CanvasDrawer
    def reserve_modules_for_test
      @canvas[3, 3, 3, 3] = 0xc0
    end
  end

  describe QR::CanvasDrawer do
    describe "#draw_function_patterns" do
      it "draws all function patterns" do
        drawer = QR::CanvasDrawer.new(QR::Version.new(7), ECC::Level::Low)
        drawer.draw_function_patterns
        drawer.canvas.normalize

        rows = convert_canvas(drawer.canvas)
        rows.should eq(FUNCTION_PATTERN_MODS_QR)
      end
    end

    describe "#draw_data_codewords" do
      it "fills codewords properly" do
        drawer = QR::CanvasDrawer.new(QR::Version.new(1), ECC::Level::Low)
        drawer.reserve_modules_for_test

        codewords = Slice(UInt8).new(21 ** 2 // 8, 154)
        drawer.draw_data_codewords(codewords)
        drawer.canvas.normalize

        rows = convert_canvas(drawer.canvas)
        rows.should eq(CODEWORDS_FILL_MODS_QR)
      end
    end

    describe "#apply_best_mask" do
      it "applies best mask" do
        drawer = QR::CanvasDrawer.new(QR::Version.new(1), ECC::Level::Low)
        drawer.canvas.data.map_with_index! { |_, idx| idx.odd?.to_unsafe.to_u8 }

        drawer.apply_best_mask.value.should eq(2)
      end
    end
  end

  describe MQR::CanvasDrawer do
    describe "#draw_function_patterns" do
      it "draws all function patterns" do
        drawer = MQR::CanvasDrawer.new(MQR::Version.new(1), ECC::Level::Low)
        drawer.draw_function_patterns
        drawer.canvas.normalize

        rows = convert_canvas(drawer.canvas)
        rows.should eq(FUNCTION_PATTERN_MODS_MQR)
      end
    end

    describe "#draw_data_codewords" do
      it "fills codewords properly" do
        drawer = MQR::CanvasDrawer.new(MQR::Version.new(1), ECC::Level::Low)
        drawer.reserve_modules_for_test

        codewords = Slice(UInt8).new(11 ** 2 // 8, 154)
        drawer.draw_data_codewords(codewords)
        drawer.canvas.normalize

        rows = convert_canvas(drawer.canvas)
        rows.should eq(CODEWORDS_FILL_MODS_MQR)
      end
    end

    describe "#apply_best_mask" do
      it "applies best mask" do
        drawer = MQR::CanvasDrawer.new(MQR::Version.new(1), ECC::Level::Low)
        drawer.canvas.data.map_with_index! { |_, idx| idx.odd?.to_unsafe.to_u8 }

        drawer.apply_best_mask.value.should eq(3)
      end
    end
  end
end
