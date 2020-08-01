require "port_midi"
require "./config"
require "./midi_consts"

# A `Track` optionally generates MIDI notes to play at each beat and
# subdivision, and sends those notes to an output stream when requested.
abstract class Track
  getter name : String
  getter value : Float64 = 0
  getter min : Float64 = 0
  getter max : Float64 = 0
  getter range : Float64 = 0
  getter running : Bool = false
  property chord_config : ChordConfig

  # Given a *value* and *min* and *max* values, return a Float64 between 0.0
  # and 1.0 inclusive.
  def self.scale(value : Float64, min : Float64, max : Float64) : Float64
    range = max - min
    return 0.0 if range == 0.0
    (val - min) / range
  end

  def initialize(@name : String, @output : OutputStream, @channel : UInt8,
                 @sound_config : SoundConfig, @score : ScoreConfig)
    @scale_cache = {} of Float64 => Float64
    @prev_notes = [] of UInt8
    @chord_config = uninitialized ChordConfig
  end

  # Different subclasses calculate their `@min` and `@max` differently, so
  # this method sets those ivars from *min* and *max* and clears our scale
  # cache as well.
  def set_minmax(min, max)
    @min, @max = min, max
    @scale_cache = {} of Float64 => Float64
  end

  # Sends MIDI bank select and program change commands.
  def start
    return if @running

    @running = true
    send(CONTROLLER + @channel, CC_VOLUME, 127)
    return if @sound_config.patch.nil?

    patch = @sound_config.patch.as(PatchConfig)
    send(CONTROLLER + @channel, CC_BANK_SELECT_MSB, patch.bank_msb)
    send(CONTROLLER + @channel, CC_BANK_SELECT_LSB, patch.bank_lsb)
    send(PROGRAM_CHANGE + @channel, patch.program, 0_u8)
  end

  # Calculates and plays notes for *beat* and *subdivision* and returns a
  # Float64. The return value depends on the subclass.
  abstract def play(beat, subdivision)

  # Sends an all-notes-off MIDI message.
  def stop
    return unless @running
    @prev_notes.each { |n| send(NOTE_OFF + @channel, n, 127_u8) }
    send(CONTROLLER + @channel, CM_ALL_NOTES_OFF, 0_u8)
    @running = false
  end

  # Maps *val* to a value between 0.0 and 1.0. Caches values to avoid
  # superfluous recacluation.
  def scale(val = @value)
    if @scale_cache.has_key?(val)
      @scale_cache[val]
    else
      @scale_cache[val] = Track.scale(val, @min, @max)
    end
  end

  # Given a *note* that is within octave zero, return one within one of the
  # octaves allowed by our sound config.
  def randomize_octave(note)
    oct = (@sound_config.min_octave..@sound_config.max_octave).to_a.sample
    (oct*12 + note).to_u8
  end

  # Turns off currently-playing notes, plays new notes, and remembers new
  # notes so they can be turned off next time this is called.
  def play_notes(notes : Array(UInt8))
    return unless @running
    if @sound_config.smooth_changes
      notes_to_turn_off = @prev_notes - notes
      notes_to_turn_on = notes - @prev_notes
    else
      notes_to_turn_off = @prev_notes
      notes_to_turn_on = notes
    end
    notes_to_turn_off.each { |n| send(NOTE_OFF + @channel, n, 127_u8) }
    # Set @prev_notes before we send the notes, so that if the app is
    # interrupted we know what notes to turn off.
    @prev_notes = @prev_notes - notes_to_turn_off + notes_to_turn_on
    notes_to_turn_on.each { |n| send(NOTE_ON + @channel, n, 127_u8) }
  end

  # Send a MIDI message immediately.
  def send(status : UInt8, data1 : UInt8 = 0_u8, data2 : UInt8 = 0_u8)
    @output.write_short(status, data1, data2, 0)
  end
end
