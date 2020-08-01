require "option_parser"
require "port_midi"
require "crt"
require "./config"
require "./time_series"
require "./conductor"
require "./gui"

# Command line options.
class Options
  property list_devices : Bool = false
  property data_file : String = ""
  property output_device : Int32 = 1
  property tempo : Int32?
  property start_time : Int64 = Time.now.to_unix - 3600
  property end_time : Int64 = 0
  property query : String = ""
  property config_file : String = ""
  property json_output : Bool = false
  property debug : Bool = false
end

# `main` and top-level supporting methods.
class Bard
  VERSION       = "0.1.0"
  DEFAULT_TEMPO = 120

  # Performs command-line parsing, initializes PortMIDI, and kicks off the
  # requested operation.
  def main
    options = parse_command_line_args
    begin
      PortMIDI.init
      if options.list_devices
        PortMIDI.list_all_devices
      elsif options.json_output
        output_json(options)
      else
        run(options)
      end
      PortMIDI.terminate
    rescue ex
      STDERR.puts ex.message
      if options.debug
        puts ex.backtrace.join("\n")
      end
      exit(1)
    end
  end

  # Reads data from Datadog and outputs it to stdout as JSON.
  def output_json(options)
    Metrics.output_json(options.start_time, options.end_time, options.query)
  end

  # Reads the config file and metrics specified in *options*, opens a
  # `PortMIDI` output stream, creates a `Conductor`, and tells it to perform
  # some music.
  def run(options : Options)
    config = BardConfig.read_yaml(options.config_file)
    config.tempo = options.tempo || config.tempo || DEFAULT_TEMPO
    metrics = request_data(options)
    output_stream = OutputStream.open(options.output_device)
    conductor = Conductor.new(metrics, output_stream, config)
    Crt.init
    Crt.start_color
    gui = GUI.new(conductor)
    conductor.gui = gui

    [Signal::HUP, Signal::INT, Signal::QUIT].each do |sig|
      sig.trap do
        conductor.stop
        gui.stop
      end
    end
    gui.start
    conductor.perform
    gui.stop
  end

  # Requests data from either a file or Datadog, as specified by *options*.
  def request_data(options)
    if options.data_file.empty?
      Metrics.from_api(options.start_time, options.end_time, options.query)
    else
      Metrics.from_file(options.data_file)
    end
  end

  # Parses command line arguments and returns an `Options` instance.
  def parse_command_line_args
    options = Options.new
    parser = OptionParser.parse! do |parser|
      parser.banner = "usage: bard [arguments]"
      parser.on("-l", "--list-devices", "List MIDI devices") { options.list_devices = true }
      parser.on("-t TEMPO", "--tempo=TEMPO", "Temp in BPM (default 120, then config file, finally command line overrides") { |t| options.tempo = t.to_i }
      parser.on("-f FILE", "--data-file=FILE", "JSON data file") { |fname| options.data_file = fname }
      parser.on("-o OUTPUT_DEVICE", "--output-device=OUTPUT_DEVICE") { |n| options.output_device = n.to_i }
      parser.on("-s TIME", "--start-time=TIME",
        "Metrics start time (default: 1 hour ago)") do |t|
        options.start_time = Time.from_yaml(t).to_unix
      end
      parser.on("-e TIME", "--end-time=TIME",
        "Metrics end time (default: start + 1 hour)") do |t|
        options.end_time = Time.from_yaml(t).to_unix
      end
      parser.on("-q QUERY", "--query=QUERY", "Datadog metrics query") { |q| options.query = q }
      parser.on("-c FILE", "--config=FILE", "Track sound configuration file") do |fname|
        options.config_file = fname
      end
      parser.on("-j", "--json", "Output JSON data to stdout; no music is played") { options.json_output = true }
      parser.on("-d", "--debug", "Debug messages (stack traces)") { options.debug = true }
      parser.on("-h", "--help", "Show this help") do
        help(parser)
        exit(0)
      end
      parser.invalid_option do |flag|
        STDERR.puts "ERROR: #{flag} is not a valid option."
        STDERR.puts parser
        exit(1)
      end
      parser
    end
    options.end_time = options.start_time + 3600 if options.end_time.zero?

    unless options.list_devices
      if options.data_file.empty? && options.query.empty? && !options.json_output
        help(parser, STDERR)
        exit(1)
      end
      if options.config_file.empty? && !options.json_output
        STDERR.puts "ERROR: config file is required"
        help(parser, STDERR)
        exit(1)
      end
    end
    options
  end

  def help(parser, f = STDOUT)
    f.puts parser
    f.puts "Either list-devices, data-file, query, or json is required."
    f.puts "If data-file or query is specified, config is required."
  end
end
