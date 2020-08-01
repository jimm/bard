require "./rhythm_track"

# This subclass of `RhythmTrack` specializes in playing bass lines. It
# always plays on channel 11.
class BassTrack < RhythmTrack
  def initialize(output_stream, sound_config, score_config)
    # That's a 10 because MIDI channels are usually referred to as 1-16 but
    # are actually numbered 0-15.
    super("Bass", output_stream, 10_u8, sound_config, score_config)
  end

  # Only play on 8th notes, not on odd 16th-notes.
  def play_on_subdiv?(beat, subdivision, probabilities)
    subdivision.even? && super
  end

  def play(beat, subdivision)
    if play_on_subdiv?(beat, subdivision, @score.bass.probability)
      # TODO volume based on busyness
      play_notes(calc_new_notes(beat, subdivision))
    end
  end

  def calc_new_notes(beat, subdivision)
    busyness = scale()
    notes = @chord_config.bass[0, [(busyness * 10.0 * @chord_config.chord.size).to_i, 1].max]
    return [] of UInt8 if notes.empty?
    [randomize_octave(notes.sample) + @chord_config.root]
  end
end
