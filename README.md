# Goban

A fast QR Code generation library written purely in Crystal. It uses less heap allocations than other implementations in Crystal, and it is more feature-complete with support for Kanji mode encoding.

The name comes from the board game [Go](https://en.wikipedia.org/wiki/Go_(game)), which have inspired the QR Code inventor to come up with a fast and accurate matrix barcode to read. Goban is the Japanese name of the board used to play Go.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     goban:
       github: soya-daizu/goban
   ```

2. Run `shards install`

## Usage

```crystal
require "goban"

qr = Goban::QRCode.encode_string("Hello World!", Goban::QRCode::ECLevel::Low)
qr.print_to_console
# => ██████████████  ████    ██  ██████████████
#    ██          ██    ██    ██  ██          ██
#    ██  ██████  ██  ██  ██  ██  ██  ██████  ██
#    ██  ██████  ██  ██    ██    ██  ██████  ██
#    ██  ██████  ██  ██████      ██  ██████  ██
#    ██          ██              ██          ██
#    ██████████████  ██  ██  ██  ██████████████
#                      ████                    
#    ████████    ██  ██  ██    ██    ██████  ██
#    ██████████    ██  ██    ██████████████  ██
#        ██    ████    ██    ████  ██      ████
#    ████  ██      ██████    ██    ██  ██  ██  
#    ████  ██████████  ██████  ████          ██
#                    ████████    ████    ██  ██
#    ██████████████      ██    ████████        
#    ██          ██    ██████████  ██  ████    
#    ██  ██████  ██    ██  ██          ██████  
#    ██  ██████  ██  ██  ██  ██  ██    ██████  
#    ██  ██████  ██  ██████  ██    ██    ██    
#    ██          ██  ██    ██  ████████      ██
#    ██████████████  ██    ██  ██████    ██    
```

To generate a PNG image, add [stumpy_png](https://github.com/stumpycr/stumpy_png) as a dependency in your shard.yml, and `require "goban/exporters/png"` to use `PNGExporter`.

```crystal
qr = Goban::QRCode.encode_string("Hello World!")
puts "Exporting with targeted size: 500"
size = Goban::PNGExporter.export(qr, "output.png", 500)
puts "Actual QR code size: #{size}"
```

See [API docs](https://soya-daizu.github.io/goban/) for more details.

## Contributing

1. Fork it (<https://github.com/soya-daizu/goban/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [soya_daizu](https://github.com/soya-daizu) - creator and maintainer
