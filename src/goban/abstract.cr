require "./abstract/*"

module Goban
  abstract struct AbstractQR
    getter version
    getter ecl
    getter canvas
    getter size

    # Prints the QR Code symbol as a text in the console. To generate the actual image file,
    # use `PNGExporter` or write your own exporter by reading each modules in `#canvas`.
    def print_to_console
      @canvas.print_to_console
    end
  end
end
