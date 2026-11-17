require "./spec_helper"

# Encodes data into every version and EC level supported by each symbol type,
# decodes the result, and checks that the original data is recovered.
# The random source has a fixed seed so that failures are reproducible.
module Goban
  ROUNDTRIP_CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:".chars

  # Returns the largest number of characters a single segment built by
  # `builder` can hold in the given version and EC level.
  def self.roundtrip_capacity(version, ecl, &builder : Int32 -> Segment)
    cap_bits = version.max_data_bits(ecl)
    low, high = 0, 8192
    while low < high
      mid = (low + high + 1) // 2
      fits = begin
        Segment.count_total_bits([builder.call(mid)], version) <= cap_bits
      rescue InputError
        false
      end
      fits ? (low = mid) : (high = mid - 1)
    end
    low
  end

  # Text lengths to try: a short one, a random one, and the full capacity.
  def self.roundtrip_lengths(capacity, random)
    [1, random.rand(1..capacity), capacity].uniq
  end

  describe QR do
    random = Random.new(20261118)

    (QR::Version::MIN..QR::Version::MAX).each do |v|
      {ECC::Level::Low, ECC::Level::Medium, ECC::Level::Quartile, ECC::Level::High}.each do |ecl|
        it "round-trips version #{v}-#{ecl}" do
          version = QR::Version.new(v)
          capacity = Goban.roundtrip_capacity(version, ecl) { |n| Segment.alphanumeric("A" * n) }

          Goban.roundtrip_lengths(capacity, random).each do |len|
            text = String.build { |io| len.times { io << ROUNDTRIP_CHARS.sample(random) } }
            qr = QR.encode_segments([Segment.alphanumeric(text)], ecl, version)
            decoded = QR.decode(qr.canvas)

            decoded.version.should eq(qr.version)
            decoded.ecl.should eq(ecl)
            decoded.segments.join(&.text).should eq(text)
          end
        end
      end
    end
  end

  describe MQR do
    random = Random.new(20261118)

    {
      {1, ECC::Level::Low},
      {2, ECC::Level::Low}, {2, ECC::Level::Medium},
      {3, ECC::Level::Low}, {3, ECC::Level::Medium},
      {4, ECC::Level::Low}, {4, ECC::Level::Medium}, {4, ECC::Level::Quartile},
    }.each do |v, ecl|
      it "round-trips version M#{v}-#{ecl}" do
        version = MQR::Version.new(v)
        # Version M1 only supports the numeric mode
        capacity = Goban.roundtrip_capacity(version, ecl) { |n| Segment.numeric("0" * n) }

        Goban.roundtrip_lengths(capacity, random).each do |len|
          text = String.build { |io| len.times { io << random.rand(10) } }
          qr = MQR.encode_segments([Segment.numeric(text)], ecl, version)
          decoded = MQR.decode(qr.canvas)

          decoded.version.should eq(qr.version)
          decoded.ecl.should eq(ecl)
          decoded.segments.join(&.text).should eq(text)
        end
      end
    end
  end

  describe RMQR do
    random = Random.new(20261118)

    RMQR::VersionValue.each do |vv|
      {ECC::Level::Medium, ECC::Level::High}.each do |ecl|
        it "round-trips version #{vv}-#{ecl}" do
          version = RMQR::Version.new(vv)
          capacity = Goban.roundtrip_capacity(version, ecl) { |n| Segment.alphanumeric("A" * n) }

          Goban.roundtrip_lengths(capacity, random).each do |len|
            text = String.build { |io| len.times { io << ROUNDTRIP_CHARS.sample(random) } }
            qr = RMQR.encode_segments([Segment.alphanumeric(text)], ecl, version)
            decoded = RMQR.decode(qr.canvas)

            decoded.version.should eq(qr.version)
            decoded.ecl.should eq(ecl)
            decoded.segments.join(&.text).should eq(text)
          end
        end
      end
    end
  end
end
