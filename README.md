# Bard

Bard turns data into music. It turns multiple streams of data points into
multiple voices, each stream with a different sound. The higher the value in
a stream, the more voices are played using that sound.

Drum and bass tracks reflect the sum of all the streams' values. The higher
the sum of the current values across all streams, the busier the drums and
bass will be.

Bard knows how to read Datadog metrics, either directly via the Datadog API
or from a saved JSON file. It can also output the metrics as JSON for later
re-reading.

Bard is written in [Crystal](https://crystal-lang.org).


## Limitiations and Bugs

Bard can only handle up to 14 separate streams at a time. That's because the
MIDI standard calls for 16 different channels, and we reserve two for the
bass and drums.

Each stream is assumed to have the same number of data points, each occuring
at the same time. The time between each data point is assumed to be
constant.

Bard can only consume data in the JSON format for
[metrics](https://docs.datadoghq.com/api/?lang=python#metrics) defined by
Datadog. It would not be too difficult to adapt Bard to read different kinds
of data sources, not just Datadog metrics.

Beats are assumed to be made up of four 16th notes, so there's currently no
way to play triplets or swing beats.


## Special 2019 Hackathon Note

Please note that Bard should be disqualified from any hackathon contests
that may happen. I started coding well before the start of the hackathon (on
my own time), knowing that I'd only have one day to work on it before having
to leave town for the rest of the hackathon week.


## Installation

First, install the packages needed to compile the `bard` application.

```sh
brew install crystal
brew install portmidi
```

Next, download the `bard` repo, install the required packages (which Crystal
calls "shards"), and compile the `bard` application.

```sh
git clone git@github.com:jimm/bard
cd bard
export PKG_CONFIG_PATH="/usr/local/opt/openssl/lib/pkgconfig"
shards install
shards build
```

Next, install an application that can receive MIDI and play sounds. On the
Mac, I use one of these two applications:

- [SimpleSynth](http://notahat.com/simplesynth/)

- [MidiPipe](http://www.subtlesoft.square7.net/MidiPipe.html) has slightly
  better sound, includes reverb, and it's _much_ more versatile. Though it
  requires a bit more setup than SimpleSynth, a setup file for MidiPipe is
  included in the `config` directory so you shouldn't have to do anything
  except load that file.


## Usage

Start your sound generation program and identify which MIDI input source it
will use. For example, on a Mac I do one of these two:

- Open SimpleSynth and change the MIDI Source to "SimpleSynth virtual
  input".

- Open MidiPipe, then within that app open `config/bard.mipi` to configure
  MidiPipe to accept MIDI input and send the notes to the internal sound
  engine.

Next, we need to determine the PortMidi **output** device number
corresponding to the MIDI input of the sound generation program (for
example, "SimpleSynth virtual input" or "MidiPipe Input 1"). The sound
generation program must be running for this step.

```sh
bin/bard -l
```

Bard will output information about all of the MIDI inputs and outputs it can
find. Make a note of the correct output device number. If you're following
along on a Mac, it's probably `2` for SimpleSynth or `3` for MidiPipe.

Next, create or edit an existing Bard track configuration YAML file. See the
example files in the `config` directory and the "Configuration Files"
section below for more information.

If you are going to use the Datadog API (as opposed to reading a
pre-existing Datadog metrics JSON file), you need to set two environment
variables.

```sh
export DATADOG_API_KEY=xxxxxxxx
export DATADOG_APP_KEY=yyyyyyyy
```

Finally, run bard, telling it what MIDI output device to use and what
metrics to fetch from Datadog or from a file. For example,

```sh
  bin/bard --output-device=2 \
      --start-time='2019-04-17T09:00:00Z' \
      --end-time='2019-04-17T10:00:00Z' \
      --query='aws.rds.load.1{*}by{app}' \
      --config=config/example2.yaml
  # or, from a file containing Datadog metrics JSON
  bin/bard --output-device=2 \
      --data-file=examples/aws_rds_load_1_by_app.json \
      --config=config/example2.yaml
```

There are short versions of all of the options. Run `bin/bard -h` to get the
full help message.


### Saving Datadog Metrics to a File

If you found a great-sounding set of data and would like to save it to a
JSON file, Bard can save it for you. Using the `--json` or `-j` command line
option will output the data as JSON to stdout, but will not play any music.

```sh
  bin/bard --json \
      --start-time='2019-04-17T09:00:00Z' \
      --end-time='2019-04-17T10:00:00Z' \
      --query='aws.rds.load.1{*}by{app}' \
      > great_data.json
```


### The Demo Script

The script [`scripts/demo.sh`] will run through a demo of Bard. See the
comment at the top of the file for caveats and instructions.


## Configuration Files

Bard configuration files describe what notes to play and what sounds to use.
See `config/example.yaml` for a fairly complete sample.

A config file contains the overall _tempo_ in beats per minute, descriptions
of the sounds to use for drums, bass, and each track, and a "score"
consisting of chords/root notes to play with their duration and, for the
bass and each drum sound, the probability that that instrument will play on
each subdivision.

The track sounds are in an array in the config file. Track sounds will
"wrap" around and be re-used if the number of data streams is greater than
the size of the array of track sounds in the config file.

A sound's full configuration consists of a _patch_ (optional, see below),
_min\_octave_ (optional, default 0), _max\_octave_ (optional, default 9),
_max\_num\_notes_ (optional, default 16), and _smooth\_changes_ (optionl,
default false). \_smooth\_changes\_ determines if a fresh set of notes is
generated every beat (false) or notes keep playing, only being added and
deleted when the track value changes enough (true). If there is no patch
within a sound, then no MIDI program change commands will be sent. In that
case, you must select the sounds manually within your MIDI sound-generation
software before running Bard.

A patch is made up of a _program_ (required) required, _bank\_msb_
(optional, default 0) and _bank\_lsb_ (optional, default 0).

(Note: both SimpleSynth and MidiPipe use the same built-in sound engine on
the Mac by default, so their patch values will be the same for the same
sounds. However, SimpleSynth _displays_ program numbers starting at 1 even
though MIDI program numbers start at 0, so you'll have to subtract one from
the displayed program number to get the proper sound in SimpleSynth. The
bank MSB and LSB values are correct and don't need adjusting.)

The bass notes in a chord can be repeated to make them more likely to play.
For example, you might want to have more '0' values to play the root of the
chord more often.

If you're into reading code, the file
[`src/bard/config.cr`](src/bard/config.cr) defines the accepted YAML format.


## Ideas for the Future

"Melody" tracks that play one note, but get busier as value increases.

In config file, output device should accept name or number, not just number.

Allow for reversal of busyness: a track might want to play fewer notes the
higher the value (for example, if high values are good and we only want to
emphasize low values).

Allow config tracks to be assigned to particular data tracks (by name, for
example). Right now it's done by position in the file and in the data.

Allow triplets and swing beats. Allow beats to be subdivided into something
different than just four 16ths.

Handle different timestamps and numbers of data points in the data. Align
them all and handle missing data points on tracks. (Could simply hold notes,
or interpolate, but couldn't interpolate if we're reading data realtime.)

Add configurable thresholds per track or globally. When values get above the
thresholds, introduce a new sound (for example, an alarm).

Allow different data input formats and sources.

Add the ability to output the generated MIDI to a standard MIDI file instead
of playing it in realtime.

Instead of generating MIDI, generate audio.

Support resizing of GUI window.


## Development

The [PortMidi](https://github.com/jimm/crystal_port_midi) Crystal shard,
along with the PortMidi C library, provides MIDI support.

The [Crt](https://github.com/maiha/crt.cr) Crystal shard provies the Curses
interface.


### Documentation

To generate the docs, run `crystal docs`.


## Contributing

1. Fork it (<https://github.com/jimm/bard/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


## Contributors

- [Jim Menard](https://github.com/jimm)
  ([jim@jimmenard.com](mailto:jim@jimmenard.com)) - creator and maintainer
