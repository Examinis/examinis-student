require_relative "rabbitmq_connection"
class AiCorrectionService
  EXCHANGE_NAME = "questions.topic"
  RESPONSE_EXCHANGE_NAME = "examinis"

  def self.submit_for_correction(payload)
    exam_id = payload[:id_exam]
    question_id = payload[:id_question]

    self.create_request_queue
    exchange = RabbitMqConnection.questions_channel.topic(EXCHANGE_NAME, durable: true)

    routing_key = "ai.feedback.requests"
    correlation_id = "correction-#{exam_id}-#{question_id}-#{Time.current.to_i}"

    # Publicando a mensagem para o serviço de IA
    exchange.publish(
      payload.to_json,
      routing_key: routing_key,
      persistent: true,
      content_type: "application/json",
      message_id: correlation_id
    )

    {
      success: true,
      message: "Question #{question_id} sent for AI correction",
      correlation_id: correlation_id
    }
  rescue StandardError => e
    Rails.logger.error("Failed to send question for AI correction: #{e.message}")
    { success: false, message: "Failed to send question for AI correction" }
  end

  def self.create_request_queue
    # Cria a fila para solicitações de correção da IA
    queue_name = "ai.feedback.requests"
    channel = RabbitMqConnection.questions_channel
    exchange = channel.topic(EXCHANGE_NAME, durable: true)

    queue = channel.queue(queue_name, durable: true)
    queue.bind(exchange, routing_key: "ai.feedback.requests")
    queue
  end

  def self.setup_feedback_consumer
    # Inicializa o consumidor apenas se ainda não estiver ativo
    return if @consumer_setup

    channel = RabbitMqConnection.questions_channel
    exchange = channel.topic(RESPONSE_EXCHANGE_NAME, durable: true)

    # Criar uma fila para receber feedback da IA com nome específico
    queue_name = "ai.feedback.responses"
    queue = channel.queue(queue_name, durable: true)

    # Vincular a fila ao exchange com o padrão de routing key que o Python está usando
    queue.bind(exchange, routing_key: "ai.feedback.response.*")

    # Configurar o consumidor para processar as mensagens
    queue.subscribe(manual_ack: false) do |delivery_info, properties, payload|
      begin
        data = JSON.parse(payload)
        Rails.logger.info("Received AI feedback: #{data}")

        if process_feedback(data)
          # Confirmar processamento bem-sucedido
          channel.acknowledge(delivery_info.delivery_tag, false)
        else
          # Rejeitar e recolocar na fila em caso de falha
          channel.reject(delivery_info.delivery_tag, true)
        end
      rescue => e
        Rails.logger.error("Error processing AI feedback message: #{e.message}")
        channel.reject(delivery_info.delivery_tag, true)
      end
    end

    @consumer_setup = true
    Rails.logger.info("AI feedback consumer setup successfully")
  end


  def self.process_feedback(payload)
    question_id = payload["id_question"]
    user_id = payload["user_id"]
    feedback = payload["feedback"]
    exam_id = payload["id_exam"]

    Rails.logger.info("Processing AI feedback for question #{question_id}, user #{user_id}")

    user_answer = UserAnswer.find_by(
      user_id: user_id,
      question_id: question_id,
      exam_id: exam_id
    )

    if user_answer
      user_answer.update(ai_feedback: feedback)
      Rails.logger.info("Saved AI feedback for user_answer #{user_answer.id}")
      true
    else
      Rails.logger.error("UserAnswer not found for user #{user_id}, question #{question_id}")
      false
    end

  rescue StandardError => e
    Rails.logger.error("Error processing AI feedback: #{e.message}")
    false
  end
end
