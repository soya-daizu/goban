require "./spec_helper"

module Goban
  describe QR::Template do
    describe ".draw_function_patterns" do
      it "draws all function patterns" do
        version = QR::Version.new(7)
        canvas = Canvas(UInt8).new(version.symbol_size, version.symbol_size, 0)
        QR::Template.draw_function_patterns(canvas, version)
        canvas.normalize

        rows = convert_canvas_to_text(canvas)
        rows.should eq(FUNCTION_PATTERN_MODS_QR)
      end
    end
  end

  describe MQR::Template do
    describe ".draw_function_patterns" do
      it "draws all function patterns" do
        version = MQR::Version.new(1)
        canvas = Canvas(UInt8).new(version.symbol_size, version.symbol_size, 0)
        MQR::Template.draw_function_patterns(canvas)
        canvas.normalize

        rows = convert_canvas_to_text(canvas)
        rows.should eq(FUNCTION_PATTERN_MODS_MQR)
      end
    end
  end

  describe RMQR::Template do
    describe ".draw_function_patterns" do
      it "draws all function patterns" do
        version = RMQR::Version.new(RMQR::VersionValue::R7x77)
        canvas = Canvas(UInt8).new(version.symbol_size.width, version.symbol_size.height, 0)
        RMQR::Template.draw_function_patterns(canvas, version, ECC::Level::Medium)
        canvas.normalize

        rows = convert_canvas_to_text(canvas)
        rows.should eq(FUNCTION_PATTERN_MODS_RMQR)
      end
    end
  end
end
