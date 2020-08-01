require "http"
require "json"

# Defines a unit within a `Series`.
class Unit
  JSON.mapping(
    family: String,
    scale_factor: Float64,
    name: String,
    short_name: String,
    plural: String,
    id: Int64
  )
end

# Defines a series of data points and associated metadata within a `Metrics`
# instance.
class Series
  JSON.mapping(
    start: Int64,
    end: Int64,
    metric: String,
    interval: Int32,
    length: Int32,
    aggr: String?,
    attributes: Hash(String, String),
    pointlist: Array({Int64 | Float64, Float64}),
    expression: String,
    scope: String,
    unit: Array(Unit?)?,
    display_name: String
  )
end

# Metrics as returned by Datadog.
class Metrics
  API_BASE_URL = "https://api.datadoghq.com/api/v1"

  JSON.mapping(
    status: String,
    res_type: String,
    series: Array(Series),
    from_date: Int64,
    to_date: Int64,
    group_by: Array(String),
    query: String,
    message: String
  )

  # Returns a JSON file and returns a `Metrics` instance.
  def self.from_file(file_path)
    data = File.open(file_path) { |file| file.gets_to_end }
    Metrics.from_json(data)
  end

  # Retrieves data from the Datadog API and returns a `Metrics` instance.
  def self.from_api(start_time_secs, end_time_secs, query)
    json = get_json(start_time_secs, end_time_secs, query)
    Metrics.from_json(json)
  end

  # Retrieves data from the Datadog API and outputs it to stdout.
  def self.output_json(start_time_secs, end_time_secs, query)
    puts(get_json(start_time_secs, end_time_secs, query))
  end

  # Retrieves data from the Datadog API and returns it as a String.
  def self.get_json(start_time_secs, end_time_secs, query)
    params = {
      "api_key"         => ENV["DATADOG_API_KEY"],
      "application_key" => ENV["DATADOG_APP_KEY"],
      "from"            => start_time_secs.to_s,
      "to"              => end_time_secs.to_s,
      "query"           => query,
    }
    get_params = HTTP::Params.encode(params)
    response = HTTP::Client.get("#{API_BASE_URL}/query?#{get_params}")
    response.body
  end
end
