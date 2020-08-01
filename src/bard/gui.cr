require "crt"
require "./conductor"

# A Curses-based GUI that displays meter bars for each track, an overall
# progress bar, and stuff like that.
class GUI
  @max_name_width : Int32
  @bar_columns : Int32
  @end_at_str : String
  @green_length : Int32
  @yellow_length : Int32

  win : Crt::Window

  def initialize(@conductor : Conductor)
    @running = false
    @win = Crt::Window.new(20, Crt.x)
    @max_name_width = [
      @conductor.tracks.map { |t| t.name.size }.max,
      @conductor.drums.name.size,
      @conductor.bass.name.size,
    ].max
    @end_at_str = Time.unix_ms(@conductor.unix_ms_at_beat(-1)).to_s
    @bar_columns = Crt.x - (@max_name_width + 8)

    @red = Crt::ColorPair.new(Crt::Color::Red, Crt::Color::Red)
    @yellow = Crt::ColorPair.new(Crt::Color::Yellow, Crt::Color::Yellow)
    @green = Crt::ColorPair.new(Crt::Color::Green, Crt::Color::Green)
    @blue = Crt::ColorPair.new(Crt::Color::Blue, Crt::Color::Blue)
    @green_length = ((2.0 * @bar_columns.to_f) / 3.0).to_i
    @yellow_length = (0.9 * @bar_columns.to_f).to_i - @green_length
  end

  # Doesn't do much.
  def start
    @running = true
  end

  # Doesn't do much.
  def stop
    @running = false
  end

  # Draws the window's contents.
  def draw(beat)
    return unless @running
    spawn do
      @win.clear
      @win.border

      @win.move(0, 1)
      @win.attribute_on(Crt::Attribute::Reverse)
      @win.print(" Bard ")
      @win.attribute_off(Crt::Attribute::Reverse)

      @win.print(18, Crt.x - 12, "^C to exit")

      @conductor.tracks.each_with_index { |t, i| draw_track(t, i) }
      draw_track(@conductor.drums, @conductor.tracks.size + 1)
      draw_track(@conductor.bass, @conductor.tracks.size + 2)

      draw_progress(beat)

      @win.refresh
    end
  end

  # Draws a track *t*'s name and meter bar.
  def draw_track(t, i)
    @win.move(i + 1, 2)
    @win.print(" %-#{@max_name_width}s " % t.name)
    draw_bar((t.scale * @bar_columns).to_i)
  end

  # Draws the progress bar given *beat*.
  def draw_progress(beat)
    beat_at_str = Time.unix_ms(@conductor.unix_ms_at_beat(beat)).to_s
    @win.print(18, 2, sprintf("%03d: %s / %s", beat, beat_at_str, @end_at_str))

    @win.move(19, 1)
    scaled_beat = Track.scale(beat.to_f64, 0.0, @conductor.timestamps.size.to_f64)
    @win.print("[")
    draw_color_bar((scaled_beat * (Crt.x - 4)).to_i, @blue)
    @win.print(19, Crt.x - 2, "]")
  end

  # Draws a bar.
  def draw_bar(len)
    return if len <= 0
    draw_len = [len, @green_length].min
    draw_color_bar(draw_len, @green)
    len -= draw_len

    return if len <= 0
    draw_len = [len, @yellow_length].min
    draw_color_bar(draw_len, @yellow)
    len -= draw_len

    return if len <= 0
    draw_color_bar(len, @red)
  end

  def draw_color_bar(len, color)
    @win.attribute_on(color)
    @win.print("=" * len)
    @win.attribute_off(color)
  end
end
