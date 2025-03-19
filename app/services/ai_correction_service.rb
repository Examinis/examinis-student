class AiCorrectionService
  EXCHANGE_NAME = "questions.topic"

  def self.submit_for_correction(exam_id, question_id, answer_data)
    exchange = RabbitMqConnection.questions_channel.topic(EXCHANGE_NAME, durable: true)

    # Routing key específica para correção de questões
    routing_key = "question.correction.#{question_id}"

    # Preparando payload com informações relevantes para a IA analisar
    payload = {
      exam_id: exam_id,
      question_id: question_id,
      student_answer: answer_data[:answer],
      correct_answer: answer_data[:correct_answer],
      question_text: answer_data[:question_text],
      submitted_at: Time.current.iso8601
    }

    # Gerando um ID de correlação para rastreamento
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

  def self.create_feedback_consumer
    queue_name = "ai.feedback.responses"

    channel = RabbitMqConnection.questions_channel
    exchange = channel.topic(EXCHANGE_NAME, durable: true)

    # Criando uma fila para receber feedback da IA
    queue = channel.queue(queue_name, durable: true)
    queue.bind(exchange, routing_key: "question.feedback.*")

    queue
  end

  # Método para processar respostas de feedback da IA
  def self.process_feedback(payload)
    # Implemente a lógica para processar feedback da IA
    # Por exemplo: atualizar a resposta da questão com o feedback da IA
    question_id = payload["question_id"]
    feedback = payload["feedback"]

    Rails.logger.info("Received AI feedback for question #{question_id}")

    # Adicione aqui a lógica para salvar o feedback no seu sistema
    # QuestionAnswer.find_by(question_id: question_id)&.update(ai_feedback: feedback)

    true
  rescue StandardError => e
    Rails.logger.error("Error processing AI feedback: #{e.message}")
    false
  end
end
