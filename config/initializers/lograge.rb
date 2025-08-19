Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  
  # Write structured logs to both STDOUT and file
  file_logger = ActiveSupport::Logger.new(Rails.root.join('log', 'development.log'))
  stdout_logger = ActiveSupport::Logger.new(STDOUT)
  
  # Broadcast to both loggers
  config.lograge.logger = ActiveSupport::BroadcastLogger.new(stdout_logger, file_logger)

  # Custom fields to include in structured logs
  config.lograge.custom_options = lambda do |event|
    {
      request_time: Time.current.iso8601,
      level: 'INFO',
      request_id: event.payload[:headers].try(:[], 'X-Request-Id') || SecureRandom.uuid,
      remote_ip: event.payload[:remote_ip],
      user_agent: event.payload[:headers].try(:[], 'User-Agent'),
      referer: event.payload[:headers].try(:[], 'Referer')
    }
  end
end