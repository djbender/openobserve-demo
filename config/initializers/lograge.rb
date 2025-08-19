Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  
  # Write structured logs to both STDOUT and file
  config.lograge.logger = ActiveSupport::Logger.new(Rails.root.join('log', 'development.log'))

  # Custom fields to include in structured logs
  config.lograge.custom_options = lambda do |event|
    {
      timestamp: Time.current.iso8601,
      level: 'INFO',
      request_id: event.payload[:headers].try(:[], 'X-Request-Id') || SecureRandom.uuid,
      remote_ip: event.payload[:remote_ip],
      user_agent: event.payload[:headers].try(:[], 'User-Agent'),
      referer: event.payload[:headers].try(:[], 'Referer')
    }
  end
end