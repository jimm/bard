require "./config"
require "./chord_track"
require "./drum_track"
require "./bass_track"
require "./gui"

# A Conductor creates tracks from metrics and coordinates their performances.
#
# Each tick of time is a 16th note (four notes per beat). This lets us play
# more interesting rhythms in the drum and bass tracks. The data tracks play
# once per beat.
#
# At most 14 tracks will play, since MIDI only has 16 channels and two are
# reserved for bass and drums.
class Conductor
  MAX_TRACKS = MIDI_CHANNELS - 2

  @sleep_time : Float64
  # Milliseconds since Unix epoch
  getter timestamps : Array(Int64)
  getter tracks : Array(ChordTrack)
  getter drums : DrumTrack
  getter bass : BassTrack

  def initialize(@metrics : Metrics, @output_stream : OutputStream, @config : BardConfig)
    @running = false
    @sleep_time = (60.0 / (config.tempo * 4)) # 16th notes
    @tracks = metrics.series[0, MAX_TRACKS].map_with_index do |series, i|
      chan = i + (i >= 9 ? 2 : 0) # skip chans reserved for bass + drums
      ChordTrack.from_series(series, output_stream, chan.to_u8,
        @config.track_sounds[i % @config.track_sounds.size], @config.score)
    end
    @drums = DrumTrack.new(output_stream, @config.drums, @config.score)
    @bass = BassTrack.new(output_stream, @config.bass, @config.score)
    @timestamps = metrics.series.first.pointlist.map { |p| p[0].to_i64 }
  end

  # Start all the tracks, play them one step at a time, and stop them.
  def perform
    start()
    chord_config_iter = @config.score.chords.each.cycle
    beats_left_in_chord = 0
    @timestamps.size.times do |beat|
      break unless @running
      if beats_left_in_chord <= 0
        chord_config = chord_config_iter.next.as(ChordConfig)
        beats_left_in_chord = chord_config.beats
        @tracks.each { |t| t.chord_config = chord_config }
        @drums.chord_config = chord_config
        @bass.chord_config = chord_config
      end
      beats_left_in_chord -= 1
      4.times do |subdiv|
        play(beat, subdiv)
        sleep(@sleep_time)
      end
    end
    stop()
  end

  # Start all the tracks.
  def start
    return if @running
    @running = true
    @tracks.each(&.start)
    @drums.start
    @bass.start
  end

  # Tell each track to play step *i*.
  def play(beat, subdiv)
    return unless @running
    @tracks.each { |t| t.play(beat, subdiv) }
    track_scale_avg = @tracks.map(&.scale).sum / @tracks.size.to_f64
    @drums.value = track_scale_avg
    @drums.play(beat, subdiv)
    @bass.value = track_scale_avg
    @bass.play(beat, subdiv)
    if subdiv == 0 && @gui
      @gui.not_nil!.draw(beat)
    end
  end

  # Stop all the tracks.
  def stop
    return unless @running
    @tracks.each(&.stop)
    @drums.stop
    @bass.stop
    @running = false
  end

  # Returns milliseconds from Unix epoch at *beat*.
  def unix_ms_at_beat(beat) : Int64
    @timestamps[beat]
  end

  def gui=(gui : GUI)
    @gui = gui
  end

  def calculate_actual_minmax : {Float64, Float64}
    sums = (0...@timestamps.size).map do |i|
      @tracks.map { |t| t.data[i] }.sum
    end
    sums.minmax
  end
end
