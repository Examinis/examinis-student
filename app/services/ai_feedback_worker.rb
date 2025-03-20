class AiFeedbackWorker
  include Sneakers::Worker

  from_queue "ai.feedback.responses",
             exchange: "questions.topic",
             exchange_type: :topic,
             routing_key: "question.feedback.*",
             durable: true

  def work(msg)
    payload = JSON.parse(msg)

    Rails.logger.info("Received AI feedback for question #{payload['question_id']}")

    # Processando o feedback utilizando o serviço AiCorrectionService
    if AiCorrectionService.process_feedback(payload)
      ack!
    else
      # Reprocessar em caso de falha
      reject!
    end
  rescue StandardError => e
    Rails.logger.error("Error processing AI feedback: #{e.message}")
    reject!
  end
end
