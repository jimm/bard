require "port_midi"

# A test output MIDI stream that captures all bytes sent via `#write_short`.
class TestOutputStream < OutputStream
  getter bytes : Array(UInt8)

  def initialize
    @stream = uninitialized LibPortMIDI::Stream
    @bytes = [] of UInt8
  end

  # This override captures the three bytes instead of sending them.
  def write_short(status : UInt8, data1 : UInt8, data2 : UInt8, when_tstamp : Int32)
    @bytes << status
    @bytes << data1
    @bytes << data2
  end

  # Erases all captured bytes.
  def clear_bytes
    @bytes = [] of UInt8
  end
end
