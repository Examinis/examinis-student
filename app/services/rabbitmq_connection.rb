class RabbitMqConnection
  def self.connection
    @connection ||= begin
      conn = Bunny.new(
        host: ENV.fetch("RABBITMQ_HOST", "localhost"),
        port: ENV.fetch("RABBITMQ_PORT", 5672),
        vhost: ENV.fetch("RABBITMQ_VHOST", "/"),
        user: ENV.fetch("RABBITMQ_USER", "guest"),
        password: ENV.fetch("RABBITMQ_PASSWORD", "guest")
      )
      conn.start
      conn
    end
  end

  def self.questions_channel
    @questions_channel ||= connection.create_channel
  end

  def self.close
    @questions_channel&.close
    @connection&.close
    @questions_channel = nil
    @connection = nil
  end
end
