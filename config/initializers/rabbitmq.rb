# config/initializers/rabbitmq.rb

unless Rails.env.test?
  Rails.application.config.after_initialize do
    begin
      AiCorrectionService.setup_feedback_consumer
      Rails.logger.info("AI feedback consumer initialized")

    rescue => e
      Rails.logger.error("Failed to initialize RabbitMQ consumer: #{e.message}")
    end
  end

  at_exit do
    RabbitMqConnection.close
  end
end
