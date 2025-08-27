Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new

  # Silence the default ActiveRecord logger to prevent duplicate SQL logs
  config.active_record.logger = nil

  file_logger = ActiveSupport::Logger.new(Rails.root.join('log', "#{Rails.env}.log"))
  file_logger.level = Logger::INFO
  stdout_logger = ActiveSupport::Logger.new(STDOUT)
  puts({stdout_level: stdout_logger.level})
  puts({file_level: file_logger.level})

  # Broadcast to both loggers
  config.lograge.logger = ActiveSupport::BroadcastLogger.new(stdout_logger, file_logger)
  puts({broadcast_debug?: config.lograge.logger.debug?})

  # Keep original Rails log disabled to prevent duplicate logs
  config.lograge.keep_original_rails_log = false

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

  # Configure SQL query logging to work with query log tags
  config.lograge.custom_payload do |controller|
    {
      host: controller.request.host
    }
  end

  # Subscribe to SQL events to log them as structured JSON
  ActiveSupport::Notifications.subscribe 'sql.active_record' do |name, start, finish, id, payload|
    next if payload[:name] == 'SCHEMA' || payload[:sql].blank?

    sql_log = {
      event: 'sql.active_record',
      timestamp: Time.current.iso8601,
      duration: ((finish - start) * 1000).round(2),
      sql: payload[:sql],
      name: payload[:name],
      connection_id: payload[:connection_id],
      binds: payload[:binds]&.map(&:value),
      type_casted_binds: payload[:type_casted_binds]
    }.compact

    config.lograge.logger.info(sql_log.to_json)
  end
end
