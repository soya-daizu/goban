require "../src/goban"
require "../src/goban/exporters/svg"

qr = Goban::QR.encode_string("Hello World!")
# Get SVG string
puts Goban::SVGExporter.svg_string(qr, 4)
# or export as a file
Goban::SVGExporter.export(qr, "test.svg")
