require "./spec_helper"

def create_test_data(_i)
  [0.0, 0.3, 0.9, 1.0, 0.5, 0.0, 0.0, 0.1]
end

def create_test_config(i)
  SoundConfig.from_yaml(
    "---
patch:
  program: #{i}
  bank_msb: #{i}
min_octave: 3")
end

def create_no_patch_test_config
  SoundConfig.from_yaml("---\nmin_octave: 3")
end

def create_score_config(i)
  ScoreConfig.from_yaml(
    "---
chords:
  -
    root: 0
    bass: [0, 7, 12, 14, -2]
    chord: [0, 7, 3, 10, 14]
    beats: 8
  -
    root: 5
    bass: [0, 7, 12, 14, -2]
    chord: [0, 7, 3, 10, 14]
    beats: 8
bass:
    probability: [
      0.95, 0.5, 0.75, 0.2,
      0.95, 0.3, 0.75, 0.1,
      0.95, 0.3, 0.75, 0.1,
      0.95, 0.3, 0.75, 0.5
      ]
drums:
  probabilities:
    kick: [
      0.95, 0.5, 0.75, 0.2,
      0.85, 0.3, 0.75, 0.1,
      0.95, 0.3, 0.75, 0.1,
      0.85, 0.3, 0.75, 0.5
      ]
    snare: [
      0.2, 0.1, 0.1, 0.1,
      0.9, 0.1, 0.1, 0.1,
      0.2, 0.1, 0.1, 0.1,
      0.9, 0.1, 0.1, 0.1,
      ]
    hh_closed: [
      0.9, 0.3, 0.7, 0.1,
      0.9, 0.3, 0.7, 0.1,
      0.9, 0.3, 0.7, 0.1,
      0.9, 0.3, 0.7, 0.1,
      ]
    hh_pedal: [
      0.1, 0.1, 0.1, 0.5,
      0.1, 0.1, 0.1, 0.5,
      0.1, 0.1, 0.1, 0.5,
      0.1, 0.1, 0.1, 0.5,
      ]
    crash: [
      0.5, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
      0.5, 0.0, 0.0, 0.0,
      ]
    tom: [
      0.5, 0.0, 0.5, 0.0,
      0.5, 0.0, 0.5, 0.0,
      0.5, 0.0, 0.5, 0.0,
      0.5, 0.0, 0.5, 0.0,
      ]
    clap: [
      0.2, 0.0, 0.5, 0.0,
      0.2, 0.0, 0.5, 0.0,
      0.2, 0.0, 0.5, 0.0,
      0.2, 0.0, 0.5, 0.0,
      ]
    cowbell: [
      0.8, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
    ]")
end

def create_test_track(i = 0, data = create_test_data(i),
                      sound_config = create_test_config(i),
                      score_config = create_score_config(i))
  TestTrack.new("test track #{i}", TestOutputStream.new, i.to_u8,
    sound_config, score_config)
end

describe Track do
  it "sends program change when started" do
    t = create_test_track(3, create_test_data(0), create_test_config(42))
    t.start
    t.bytes.should eq([
      CONTROLLER + 3_u8, CC_VOLUME, 127_u8,
      CONTROLLER + 3_u8, CC_BANK_SELECT_MSB, 42_u8,
      CONTROLLER + 3_u8, CC_BANK_SELECT_LSB, 0_u8,
      PROGRAM_CHANGE + 3_u8, 42_u8, 0_u8,
    ])
  end

  it "does not send a program change if there is no patch" do
    t = create_test_track(3, create_test_data(0), create_no_patch_test_config())
    t.start
    t.bytes.should eq([CONTROLLER + 3_u8, CC_VOLUME, 127_u8])
  end

  it "sends an all-notes-off message when stopped" do
    t = create_test_track(3, create_test_data(0), create_no_patch_test_config())
    t.start
    t.stop
    t.bytes.should eq([
      CONTROLLER + 3_u8, CC_VOLUME, 127_u8,
      CONTROLLER + 3_u8, CM_ALL_NOTES_OFF, 0_u8,
    ])
  end
end
