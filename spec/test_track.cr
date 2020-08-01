require "../src/bard/track"
require "./test_output_stream"

# A track that uses a `TestOutputStream` and captures bytes sent via the
# `#send` method.
class TestTrack < Track
  getter test_output : TestOutputStream

  def initialize(name : String, output : OutputStream, channel : UInt8,
                 sound_config : SoundConfig, score_config : ScoreConfig)
    super(name, output, channel, sound_config, score_config)
    @test_output = @output.as(TestOutputStream)
  end

  def play(_beat, _subdivision)
  end

  # This override sends the bytes to our test output stream.
  def send(status : UInt8, data1 : UInt8 = 0_u8, data2 : UInt8 = 0_u8)
    @test_output.write_short(status, data1, data2, 0)
  end

  # Returns all bytes sent to the stream since the track was created or the
  # last time `#clear_bytes` was sent.
  def bytes
    @test_output.bytes
  end

  # Erases all captured bytes.
  def clear_bytes
    @test_output.clear_bytes
  end
end
