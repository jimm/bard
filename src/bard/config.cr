require "yaml"
require "time"

# Defines a chord. All note offsets are in half steps.
#
# - root: The root of the chord, relative to C. 0 = C, 1 = C#.
#
# - bass: The note offsets the bass may play. More common notes (for
#   example, root and fifth) should be earlier in the array.
#
# - chord: The note offsets that make up the chord. For example, a simple
#   major chord would be [0, 4, 7]. More common notes should be earlier in
#   the array.
#
# - beats: The number of beats to hold this chord
class ChordConfig
  YAML.mapping(
    root: UInt8,
    bass: Array(UInt8),
    chord: Array(UInt8),
    beats: {type: Int32, default: 4}
  )
end

# Defines per-subdivision probabilties for playing a bass note.
class BassConfig
  YAML.mapping(
    probability: Array(Float64)
  )
end

# Defines per-subdivision probabilties for playing all of the various drum
# instruments.
class DrumProbabilities
  YAML.mapping(
    kick: Array(Float64),
    snare: Array(Float64),
    hh_closed: Array(Float64),
    hh_pedal: Array(Float64),
    crash: Array(Float64),
    tom: Array(Float64),
    clap: Array(Float64),
    cowbell: Array(Float64)
  )
end

# Defines the probabilities for all instruments in the drum set.
class DrumConfig
  YAML.mapping(
    probabilities: DrumProbabilities
  )
end

# Defines what notes to play for `ChordTrack` instances, and what
# probabilities to use for playing the bass and drums on beat subdivisions.
class ScoreConfig
  YAML.mapping(
    chords: Array(ChordConfig),
    bass: BassConfig,
    drums: DrumConfig,
  )
end

# Describes what MIDI patch to use. Patches are optional within a
# `ScoreConfig`. If specifed, `program` is required but the bank values are
# optional.
class PatchConfig
  YAML.mapping(
    program: UInt8,
    bank_msb: {type: UInt8, default: 0_u8},
    bank_lsb: {type: UInt8, default: 0_u8},
  )
end

# Defines a track sound.
#
# - patch: a `PatchConfig` (optional)
# - min_octave: limits range of notes produced; optional, default 0
# - max_octave: limits range of notes produced; optional, default 9
# - max_num_notes: maximum number of notes to play; optional, default 16
# - smooth_changes: If `false`, a fresh set of notes is generated every
#   beat. If `true`, notes keep playing, only being added and deleted when
#   the track value changes enough. Optional, default is `false`.
class SoundConfig
  YAML.mapping(
    patch: PatchConfig?,
    min_octave: {type: Int32, default: 0},
    max_octave: {type: Int32, default: 9},
    max_num_notes: {type: Int32, default: 16},
    smooth_changes: {type: Bool, default: false}
  )
end

# Top-level Bard app configuration.
#
# - tempo: beats per minute; optional, default 120
# - drums: a `SoundConfig` for the drum track
# - bass: a `SoundConfig` for the bass track
# - track_sounds: an array of `SoundConfig`s for the tracks. If the number
#   of data streams is greater than the number of specified track sounds,
#   then the sound configs are cycled through back from the beginning.
class BardConfig
  YAML.mapping(
    tempo: {type: Int32, default: 120},
    drums: SoundConfig,
    bass: SoundConfig,
    track_sounds: Array(SoundConfig),
    score: ScoreConfig
  )

  # Reads a YAML file and returns a `BardConfig`.
  def self.read_yaml(path)
    data = File.open(path) { |file| file.gets_to_end }
    from_yaml(data)
  end
end
