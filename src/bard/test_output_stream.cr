# A test output MIDI stream.
class TestOutputStream
  getter first_event : LibPortMIDI::Event
  getter num_events

  def initialize
    @stream = uninitialized LibPortMIDI::Stream
    @first_event = uninitialized LibPortMIDI::Event
    @num_events = -1
  end

  def write(buffer : Pointer(LibPortMIDI::Event), length : Int32) : Int32
    @first_event = buffer.value
    @num_events = length
  end
end
