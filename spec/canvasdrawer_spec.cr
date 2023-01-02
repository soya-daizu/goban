require "./spec_helper"

module Goban
  struct QR::CanvasDrawer
    def reserve_modules_for_test
      @canvas.fill_module(8, 8, 7, 7, 0xc0)
    end
  end

  describe QR::CanvasDrawer do
    describe "#draw_function_patterns" do
      it "draws all function patterns" do
        drawer = QR::CanvasDrawer.new(QR::Version.new(7), ECC::Level::Low)
        drawer.draw_function_patterns
        drawer.canvas.normalize

        rows = convert_canvas(drawer.canvas)
        rows.should eq(FUNCTION_PATTERN_MODS)
      end
    end

    describe "#draw_data_codewords" do
      it "fills codewords properly" do
        drawer = QR::CanvasDrawer.new(QR::Version.new(1), ECC::Level::Low)
        drawer.reserve_modules_for_test

        codewords = Slice(UInt8).new(21 ** 2 - 7 ** 2, 154)
        drawer.draw_data_codewords(codewords)
        drawer.canvas.normalize

        rows = convert_canvas(drawer.canvas)
        rows.should eq(CODEWORDS_FILL_MODS)
      end
    end

    describe "#apply_best_mask" do
      it "applies best mask" do
        drawer = QR::CanvasDrawer.new(QR::Version.new(1), ECC::Level::Low)
        drawer.canvas.modules.map_with_index! { |_, idx| idx.odd?.to_unsafe.to_u8 }

        drawer.apply_best_mask.value.should eq(2)
      end
    end
  end
end
