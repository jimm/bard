#!/bin/bash
#
# usage: demo.sh [portmidi_output_device_number]
#
# This script acts as a simple auto-demo for Bard. It assumes you're using
# MidiPipe. Default device number is 3. Run `bard -l` to display the list of
# device numbers available.

output_device_number=${1:3}

look_at_me() {
osascript - <<EOS
tell application "iTerm2"
  activate
end tell
EOS
}

cd "$(dirname "$0")/.."

open config/bard.mipi
look_at_me

echo "Welcome to Bard!"
sleep 2
echo "Bard turns streams of data into music."
sleep 2
echo "Let's hear two examples."
echo "They both compress their time ranges down to about 2-3 minutes."
echo "Use ^C to interrupt the playing at any time; the demo will continue."
sleep 4

echo
echo "First, we'll hear database server CPU loads over an hour."
echo "(Don't worry, I'll interrupt it so you don't have to hear the whole thing.)"
look_at_me
sleep 4
bin/bard -o $output_device_number \
         -c config/example2.yaml \
         -f examples/aws_rds_load_1_by_app.json

echo
echo "Next, let's listen to the number of database queries over a two-day period."
echo "This example uses different chords and a different tempo."
look_at_me
sleep 4
bin/bard -o $output_device_number \
         -c config/example.yaml \
         -f examples/db_avg_query_count.json

open 'https://github.com/jimm/bard'
echo
echo
echo "Thanks for listening! Some more info about Bard:"
echo "- Each data stream becomes a different track (sound)"
echo "- The higher the data stream's value, the more notes played"
echo "- Drums and bass reflect overall busyness"
echo "- The sounds to use and notes to play are defined in a configuration file"
echo "- The drum hits are described as probabilities, per beat subdivision"
echo "- Data comes from Datadog metrics (or that data saved to a JSON file)"
