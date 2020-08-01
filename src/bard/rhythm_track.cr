require "./track"

# A `RhythmTrack` plays notes on subdivisions of the beat.
#
# Each beat subdivision, a `RhythmTrack` may generate MIDI notes to play.
# Deciding which subdivisions to play on is the responsibililty of
# `#play_on_subdiv?`. Which notes to play is left to the subclasses of ths
# class.
abstract class RhythmTrack < Track
  def initialize(name, output_stream, channel, sound_config, score_config)
    super
    set_minmax(0.0, 1.0)
  end

  # Rhythm tracks get their values set by the conductor based on the values
  # of all the chord tracks. Our min/max already reflect the possible
  # min/max values across all tracks.
  def value=(val : Float64)
    @value = val
  end

  # This override avoids any calculation if possible, since our `@value` is
  # already the scaled value we need.
  def scale(val = @value)
    return val if val == @value
    super
  end

  # Returns true if we should play something at this *beat* and
  # *subdivision*. *probabilities* is an Array(Float64). Beats are
  # subdivided into four subdivisions. If `probablities.size > 4`, this
  # means that the rhythm pattern should be spread over (size / 4) beats.
  #
  # Since some `SubdivTrack` subclasses can play more than one note on each
  # *beat* and *subdivision* and each note can play on different
  # subdivisions, we need to pass in the probability array.
  def play_on_subdiv?(beat, subdivision, probabilities) : Bool
    num_beats_in_pattern = probabilities.size / 4
    subdivision_in_pattern = (beat % num_beats_in_pattern) * 4 + subdivision

    # TODO decrease rand a bit by busyness level, making notes more likely
    # the more busy the global data. Can't just multiply the two, since
    # busyness might normally be pretty low globally.
    #
    # busyness = scale()
    Random.rand <= probabilities[subdivision_in_pattern]
  end
end
