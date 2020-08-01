require "./rhythm_track"
require "./drum_note_consts"

# This subclass of `RhythmTrack` specializes in playing drum tracks. It
# always plays on channel 10 (the standard MIDI channel for drums).
class DrumTrack < RhythmTrack
  # This macro generates code that adds *note* to `new_notes` if
  # `play_on_subdiv?` returns true for the probability array named
  # *prob_name*.
  #
  # This isn't really necessary. Each of the macro calls below could just as
  # easily use the inline code. I just wanted to show off macros in Crystal.
  # You can't do this without macros, since *prob_name* is an instance
  # variable name and you can't get those values dynamically, given a string
  # or symbol. At least, I don't think so; I'm no Crystal expert yet.
  macro maybe_note(note, prob_name)
    new_notes << {{note}} if play_on_subdiv?(beat, subdivision, probs.{{prob_name}})
  end

  def initialize(output_stream, sound_config, score_config)
    # That's a 9 because MIDI channels are usually referred to as 1-16 but
    # are actually numbered 0-15.
    super("Drums", output_stream, 9_u8, sound_config, score_config)
  end

  def play(beat, subdivision)
    probs = @score.drums.probabilities
    new_notes = [] of UInt8
    maybe_note(ACOUSTIC_BASS_DRUM, kick)
    maybe_note(ACOUSTIC_SNARE, snare)
    maybe_note(CLOSED_HI_HAT, hh_closed)
    maybe_note(PEDAL_HI_HAT, hh_pedal)
    maybe_note(CRASH_CYMBAL_1, crash)
    maybe_note(LOW_MID_TOM, tom)
    maybe_note(HAND_CLAP, clap)
    maybe_note(COWBELL, cowbell)
    play_notes(new_notes)
  end
end
