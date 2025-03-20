class QuestionAnswersController < ApplicationController
  def request_ai_correction
    user_answer_id = params[:user_answer]
    user_answer = UserAnswer.find(user_answer_id)
    question = Question.find(user_answer.question_id)

    correct_option = question.options.find_by(is_correct: true)
    choosen_option = Option.find(user_answer.option_id)

    answer_data = {
      id_exam: user_answer.exam_id,
      id_question: user_answer.question_id,
      question_text: question.text,
      choosen_option: choosen_option.description,
      correct_option: correct_option.description,
      user_id: user_answer.user_id
    }

    Rails.logger.info("Sending question for AI correction: #{answer_data}")

    result = AiCorrectionService.submit_for_correction(answer_data)

    Rails.logger.info("AI correction result: #{result}")

    redirect_to "/exams/answered/#{user_answer.exam_id}",
          notice: "Solicitação de revisão enviada! O feedback estará disponível em breve."
  end
end
