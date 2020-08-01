require "./track"
require "./time_series"

# This subclass of `Track` turns a `Series` of data into zero or more notes
# at a time, changing once per beat.
class ChordTrack < Track
  getter data : Array(Float64)

  # Creates a `ChordTrack` given a *series*, an *output_stream*, a MIDI
  # *channel*, and a *sound_config* and a *score_config*.
  def self.from_series(series, output_stream, channel, sound_config, score_config)
    data = series.pointlist.map { |fs| fs[1] }
    new(series.scope, output_stream, channel, sound_config, score_config, data)
  end

  def initialize(name, output, channel, sound_config, score_config, @data)
    super(name, output, channel, sound_config, score_config)
    min, max = @data.minmax
    set_minmax(min, max)
    @chord_changed = false
  end

  # Calculates `@value`, sets track volume, and plays the notes to play at
  # *beat* and *subdivision*. Returns the current data value so that drums
  # and bass can act upon the values of all the chord tracks. Only plays
  # when *subdivision* is zero (that is, on the start of the beat), but
  # always returns the current value.
  def play(beat, subdivision)
    @value = @data[beat]
    if subdivision == 0
      set_volume
      play_notes(calc_new_notes())
    end
  end

  # Lowers the track volume a bit the higher our `@value`, because more notes
  # will get played.
  def set_volume
    volume = (96 + (1.0 - scale() * 31)).to_u8
    send(CONTROLLER + @channel, CC_VOLUME, volume)
  end

  # Given the current data `@value`, select notes to play from
  # `@chord_config`. The higher the val, the more notes we play and the more
  # notes we select from the available ones in the chord. Since notes are
  # selected from the beginning of `@chord_config`, the values at the front
  # are more likely to be played.
  #
  # TODO make sure there are no repeated notes in all cases.
  def calc_new_notes : Array(UInt8)
    busyness = scale()
    num_notes = (busyness * @sound_config.max_num_notes).to_i
    prev_num_notes = @prev_notes.size
    if @chord_changed || !@sound_config.smooth_changes
      @chord_changed = false
      offsets = @chord_config.chord[0, (busyness * @chord_config.chord.size).to_i]
      return [] of UInt8 if offsets.empty?
      _generate_notes_in_range(offsets, num_notes)
    elsif num_notes > prev_num_notes
      # # use full range of potential notes, just select less of them
      offsets = @chord_config.chord[0, (busyness * @chord_config.chord.size).to_i]
      return @prev_notes if offsets.empty?
      @prev_notes + _generate_notes_in_range(offsets, num_notes - prev_num_notes)
    elsif num_notes < prev_num_notes
      # remove random offsets
      notes = @prev_notes.dup
      return notes if notes.empty?
      (prev_num_notes - num_notes).times { |_| notes.delete_at(Random.rand(notes.size)) }
      notes
    else
      @prev_notes
    end
  end

  def chord_config=(chord_config : ChordConfig)
    super
    @chord_changed = true
  end

  # Ensures no notes are duplicated.
  def _generate_notes_in_range(offsets, num_notes)
    notes = [] of UInt8
    while num_notes > 0
      note = randomize_octave(offsets.sample) + @chord_config.root
      unless notes.include?(note)
        notes << note
        num_notes -= 1
      end
    end
  end
end
