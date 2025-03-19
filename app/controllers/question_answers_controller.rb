class QuestionAnswersController < ApplicationController
  def request_ai_correction
    user_answer = UserAnswer.find(params[:id])
    correct_answer = user_answer.question.each { |q| }

    # Preparando os dados para envio
    answer_data = {
      answer: user_answer.option.text,
      correct_answer: user_answer.question,
      question_text: user_answer.question.text
    }

    # Enviando para correção via AiCorrectionService
    result = AiCorrectionService.submit_for_correction(exam_id, question_id, answer_data)

    if result[:success]
      puts result
      # Atualiza o status da resposta para indicar que está em análise pela IA
      # question_answer.update(ai_correction_requested: true,
      #                       ai_correction_correlation_id: result[:correlation_id])

      # redirect_to question_answer_path(question_answer), notice: "Question sent for AI analysis"
    else
      redirect_to question_answer_path(question_answer), alert: "Failed to send question for AI analysis"
    end
  end
end
