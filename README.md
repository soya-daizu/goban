# Goban

A fast and efficient QR Code encoder library written purely in Crystal. It is significantly faster (4-5x) and uses fewer heap allocations (-95%) compared to the other implementation in Crystal ([spider-gazelle/qr-code](https://github.com/spider-gazelle/qr-code)), and it supports wider QR Code standard features such as Kanji mode encoding. It also supports generating Micro QR Code and rMQR Code symbols.

The implementation aims compliance with following standards:

- [ISO/IEC 18004:2015](https://www.iso.org/standard/62021.html)/[JIS X 0510:2018](https://webdesk.jsa.or.jp/books/W11M0090/index/?bunsyo_id=JIS+X+0510%3A2018)
- [ISO/IEC 23941:2022](https://www.iso.org/standard/77404.html)

The name comes from the board game [Go](<https://en.wikipedia.org/wiki/Go_(game)>), which inspired the QR Code inventor to come up with a fast and accurate matrix barcode to read. 碁盤(Goban) literally means [Go board](https://en.wikipedia.org/wiki/Go_equipment#Board) in Japanese.

_"QR Code" is a registered trademark of Denso Wave Incorporated._
https://www.qrcode.com/en/patent.html

## Benchmark

Comparing it/s and heap allocations between Goban and spider-gazelle/qr-code:

```crystal
require "benchmark"
require "qr-code"
require "goban"

Benchmark.ips do |x|
  x.report("qr-code") { QRCode.new("Hello World!", level: :h) }
  x.report("goban") { Goban::QR.encode_string("Hello World!", Goban::ECC::Level::High) }
end
```

```
qr-code   3.49k (286.18µs) (± 1.51%)   149kB/op   5.33× slower
  goban  18.61k ( 53.74µs) (± 1.81%)  8.08kB/op        fastest
```

## Features

| QR Code Type      | Encoding | Decoding |
| ----------------- | :------: | :------: |
| QR Code Model 1\* |    -     |    -     |
| QR Code Model 2   |    ✓     |    ✓     |
| Micro QR Code     |    ✓     |    -     |
| rMQR Code         |    ✓     |    -     |

\* QR Code Model 1 will not be supported as it is considered obsolete.

## Roadmap

- Encoding
  - Add ECI mode encoding
  - Support structured append of symbols
- Decoding
  - Support decoding Micro QR Code and rMQR code symbols

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     goban:
       github: soya-daizu/goban
   ```

2. Run `shards install`

## Usage

A simple example to generate a QR Code for the given string and output to the console:

```crystal
require "goban"

qr = Goban::QR.encode_string("Hello World!", Goban::ECC::Level::Low)
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

`Goban::ECC::Level` represents the ECC (Error Correction Coding) level to use when encoding the data. The available options are:

| Level    | Error Correction Capability |
| -------- | --------------------------- |
| Low      | Approx 7%                   |
| Medium   | Approx 15%                  |
| Quartile | Approx 25%                  |
| High     | Approx 30%                  |

The default ECC level is `Medium`. Use `Low` if you want your QR Code to be as compact as possible, or increase the level to `Quartile` or `High` if you want it to be more resistant to damage.

Higher ECC levels are especially capable of interpolating a large chunk of loss in the symbol such as by tears and stains. Typically, it is not necessary to set the ECC level high for display purposes on the screen.

### Using exporters to generate a PNG and SVG image

To generate a PNG image, add [stumpy_png](https://github.com/stumpycr/stumpy_png) as a dependency in your shard.yml, and `require "goban/exporters/png"` to use `Goban::PNGExporter`:

```crystal
require "goban/exporters/png"

qr = Goban::QR.encode_string("Hello World!")
puts "Exporting with targeted size: 500"
size = Goban::PNGExporter.export(qr, "output.png", 500)
puts "Actual QR Code size: #{size}"
```

`Goban::SVGExporter` requires no external dependency and can be used like below:

```crystal
require "goban/exporters/svg"

qr = Goban::QR.encode_string("Hello World!")
# Get SVG string
puts Goban::SVGExporter.svg_string(qr, 4)
# or export as a file
Goban::SVGExporter.export(qr, "test.svg")
```

Alternatively, you can write your own export logic by iterating over the canvas of the QR Code object.

```crystal
qr = Goban::QR.encode_string("Hello World!")
qr.canvas.each_row do |row, y|
  row.each do |mod, x|
    # mod is each module (pixel or dot in other words) included in the symbol
    # and the value is either 0 (= light) or 1 (= dark)
  end
end
```

### About the encoding modes and the text segmentation

The `Goban::QR.encode_string` method under the hood encodes a string to an optimized sequence of text segments where each segment is encoded in one of the following encoding modes:

| Mode         | Supported Characters        |
| ------------ | --------------------------- |
| Numeric      | 0-9                         |
| Alphanumeric | 0-9 A-Z \s $ % \* + - . / : |
| Byte         | Any UTF-8 characters        |
| Kanji        | Any Shift-JIS characters    |

The `Byte` mode supports the widest range of characters but it is inefficient and produces longer data bits, meaning that when comparing the two QR Code symbols, one encoded entirely in the `Byte` mode and the other encoded in the appropriate mode for each character\*, the former one can be more challenging to scan and decode than the other given that both symbols are printed in the same size.

\* Because each text segment includes additional header bits to indicate its encoding mode, simply encoding each character in the supported mode that has the smallest character set may not always produce the most optimal segments. Goban addresses this by using the technique of dynamic programming.

Finding out the optimal segmentation requires some processing, so if you are generating thousands of QR Codes with all the same limited sets of characters, you may want to hard-code the text segments and apply the characters to those to generate the QR Codes.

This can be done by using the `Goban::QR.encode_segments` method, which is the lower-level method used by the `Goban::QR.encode_string` method.

```crystal
segments = [
  Goban::Segment.kanji("こんにち"),
  Goban::Segment.byte("wa"),
  Goban::Segment.kanji("、世界！"),
  Goban::Segment.alphanumeric(" 123"),
]
# Note that when using this method, you have to manually assign the version (= size) of the QR Code.
qr = Goban::QR.encode_segments(segments, Goban::ECC::Level::Low, 2)
```

The optimal segments and version to hard-code can be figured out by manually executing the `Goban::QR.determine_version_and_segments` method.

### Generating Micro QR Codes

Micro QR Codes can be generated just like regular QR Codes using the `Goban::MQR.encode_string` or `Goban::MQR.encode_segments` methods.

```crystal
mqr = Goban::MQR.encode_string("Hello World!", Goban::ECC::Level::Low)
mqr.print_to_console
# => ██████████████  ██  ██  ██  ██  ██
#    ██          ██  ██        ██
#    ██  ██████  ██    ██    ████
#    ██  ██████  ██  ██      ██████  ██
#    ██  ██████  ██      ██  ██████  ██
#    ██          ██  ██        ██  ██
#    ██████████████  ██████    ██    ██
#                            ██████  ██
#    ██    ██  ██████  ████  ██      ██
#      ██████████            ██
#    ████    ████████  ██████████  ██
#      ██      ██  ████    ████
#    ████████  ██  ██  ████  ██████  ██
#              ██████████████████
#    ██████      ████████        ██
#        ██      ██  ██████  ████
#    ██████  ██    ██  ████  ██      ██
```

You can learn more about the text segments and encoding modes [above](#about-the-encoding-modes-and-the-text-segmentation).

Note that Micro QR Code has strong limitations in the data capacity, supported encoding modes, and error correction capabilities.

| Version | Supported ECC Level         | Supported Modes                    |
| ------- | --------------------------- | ---------------------------------- |
| M1      | None (Error Detection Only) | Numeric                            |
| M2      | Low, Medium                 | Numeric, Alphanumeric              |
| M3      | Low, Medium                 | Numeric, Alphanumeric, Byte, Kanji |
| M4      | Low, Medium, Quartile       | Numeric, Alphanumeric, Byte, Kanji |

Data capacity for each combination of the symbol version and ECC level can be found [here](https://www.qrcode.com/en/codes/microqr.html).

Since the version M1 doesn't support error correction at all, the value passed as the ECC level will be ignored.

### Generating rMQR Codes

Just like regular QR Codes and Micro QR Codes, rMQR Codes can also be generated using the `Goban::RMQR.encode_string` and `Goban::RMQR::encode_segments` methods.

```crystal
# Note that rMQR Code only supports Medium and High ECC Level
rmqr = Goban::RMQR.encode_string("Hello World!", Goban::ECC::Level::Medium)
puts rmqr.version.value
# => R13x27
rmqr.print_to_console
# => ██████████████  ██  ██  ██  ██  ██  ██  ██  ██  ██████
#    ██          ██        ████████  ██████              ██
#    ██  ██████  ██  ████    ██        ██    ██  ████    ██
#    ██  ██████  ██    ████      ████    ████  ██    ██
#    ██  ██████  ██  ██████  ████████████  ██████    ██████
#    ██          ██      ████████  ██  ██          ██
#    ██████████████  ██████        ██  ██  ████  ██  ██████
#                    ██  ████    ████      ██      ████
#    ████  ██  ██            ██████████    ██    ██████████
#      ████  ██████████  ██    ██    ██  ██      ██      ██
#    ██  ████            ████      ██  ██    ██  ██  ██  ██
#    ██        ██████  ██████  ██  ██████        ██      ██
#    ██████  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██████████
```

However, unlike regular QR Codes and Micro QR Codes, rMQR Codes has different sizes in width and height, which means that there can be multiple versions that are optimal in terms of capacity. rMQR Code versions are represented in the format of `R{height}x{width}` with the following available combinations.

|     | 27  | 43  | 59  | 77  | 99  | 139 |
| --- | :-: | :-: | :-: | :-: | :-: | :-: |
| R7  |  -  |  ✓  |  ✓  |  ✓  |  ✓  |  ✓  |
| R9  |  -  |  ✓  |  ✓  |  ✓  |  ✓  |  ✓  |
| R11 |  ✓  |  ✓  |  ✓  |  ✓  |  ✓  |  ✓  |
| R13 |  ✓  |  ✓  |  ✓  |  ✓  |  ✓  |  ✓  |
| R15 |  -  |  ✓  |  ✓  |  ✓  |  ✓  |  ✓  |
| R17 |  -  |  ✓  |  ✓  |  ✓  |  ✓  |  ✓  |

`SizingStrategy` is used to prioritize one version than the other based on whether you want the symbol to be smaller in total area, width, or height. By default, it tries to balance the width and height, keeping the total area as small as possible.

For example, if you want to encode the same text but prioritizing smaller height rather than area:

```crystal
rmqr = Goban::RMQR.encode_string("Hello World!", Goban::ECC::Level::Medium, Goban::RMQR::SizingStrategy::MinimizeHeight)
puts rmqr.version.value
# => R7x77
rmqr.print_to_console
# => ██████████████  ██  ██  ██  ██  ██  ██  ██  ██  ██████  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██████  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██████
#    ██          ██  ██    ████████    ██████        ██  ██          ██  ████  ████  ██  ████        ██  ██  ████    ██        ██  ██    ██████          ██  ██
#    ██  ██████  ██    ██████████      ██████    ██  ██████      ██████    ██████████████      ████  ████████████  ██    ████  ██  ██    ██  ██    ████████████
#    ██  ██████  ██  ██████  ██  ██    ████        ████  ██  ██████████  ████  ██  ██  ██████  ██████    ██    ██████      ██        ████  ██████    ██      ██
#    ██  ██████  ██  ████    ██          ████    ██████████          ██  ██      ██  ██████  ██        ████████    ██  ██  ██          ████████  ██████  ██  ██
#    ██          ██  ██████  ██████  ██████    ████████  ██    ██  ██        ████  ██  ██    ██  ██  ██  ██  ██      ████████  ██  ██  ████    ████  ██      ██
#    ██████████████  ██  ██  ██  ██  ██  ██  ██  ██  ██████  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██████  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██████████
```

## API Documentations

The API docs for the current master branch are available from the link below:

[API docs](https://soya-daizu.github.io/goban/)

You might want to first look at the `Goban::QR` or one of the exporters (`Goban::PNGExporter` and `Goban::SVGExporters`) to understand how to use this library.

## Contributing

1. Fork it (<https://github.com/soya-daizu/goban/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [soya_daizu](https://github.com/soya-daizu) - creator and maintainer

## Credits

- [Optimal text segmentation for QR Codes](https://www.nayuki.io/page/optimal-text-segmentation-for-qr-codes)
- [zxing/zxing](https://github.com/zxing/zxing)
- [OUDON/rmqrcode-python](https://github.com/OUDON/rmqrcode-python)
