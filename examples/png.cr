require "../src/goban"
require "../src/goban/exporters/png"

qr = Goban::QRCode.encode_string("Hello World!")
puts "Exporting with targeted size: 500"
size = Goban::PNGExporter.export(qr, "test.png", 500)
puts "Actual QR code size: #{size}"
