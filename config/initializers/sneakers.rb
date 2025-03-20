require "sneakers"

Sneakers.configure(
  amqp: ENV.fetch("RABBITMQ_URL", "amqp://guest:guest@localhost:5672"),
  exchange: "questions.topic",
  exchange_type: :topic,
  durable: true,
  ack: true,
  heartbeat: 30,
  workers: 2,
  threads: 1,
  prefetch: 1,
  log: Rails.logger
)

Sneakers.logger = Rails.logger
Sneakers.logger.level = Logger::INFO
