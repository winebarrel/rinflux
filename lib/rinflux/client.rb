class Rinflux::Client
  DEFAULT_ADAPTERS = [
    Faraday::Adapter::NetHttp,
    Faraday::Adapter::Test
  ]

  def initialize(options = {})
    @options = options
    host = @options.delete(:host) || 'localhost'
    port = @options.delete(:port) || 8086
    @options[:url] ||= "http://#{host}:#{port}"

    @conn = Faraday.new(options) do |faraday|
      faraday.request  :url_encoded
      faraday.response :json, :content_type => /\bjson$/
      faraday.response :raise_error

      yield(faraday) if block_given?

      unless DEFAULT_ADAPTERS.any? {|i| faraday.builder.handlers.include?(i) }
        faraday.adapter Faraday.default_adapter
      end
    end
  end

  def query(params = {})
    response = @conn.get do |req|
      req.url '/query'
      req.params = params
      yield(req) if block_given?
    end

    response.body
  end

  def write(measurement, value, options = {})
    unless value.is_a?(Hash)
      value = {:value => value}
    end

    line = []
    tags = options.delete(:tags) || {}
    timestamp = options.delete(:timestamp)

    # kye
    if tags.empty?
      line << measurement
    else
      line << [
        escape(measurement),
        tags.map {|k, v| "#{escape(k)}=#{escape(v)}" }.join(',')
      ].join(',')
    end

    # field
    line << value.map {|k, v|
      unless [Numeric, TrueClass, FalseClass].any? {|c| v.is_a?(c) }
        v = quote(v)
      end

      "#{escape(k)}=#{v}"
    }.join(',')

    # timestamp
    if timestamp
      if timestamp.is_a?(Time)
        timestamp = '%d%09d' % [timestamp.to_i, timestamp.nsec]
      end

      line << timestamp
    end

    @conn.post do |req|
      req.url '/write'
      req.params = options
      req.body = line.join(' ')
      yield(req) if block_given?
    end
  end

  private

  def escape(str)
    str.to_s.gsub(/[ ,]/) {|m| '\\' + m }
  end

  def quote(str)
    str = str.to_s.gsub('"', '\\"')
    %!"#{str}"!
  end
end
