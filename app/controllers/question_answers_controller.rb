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
      option_escolhida: choosen_option.description,
      option_correta: correct_option.description,
      user_id: user_answer.user_id
    }

    Rails.logger.info("Sending question for AI correction: #{answer_data}")

    result = AiCorrectionService.submit_for_correction(answer_data)

    puts result
    # if result
    #   puts result
    #   # redirect_to question_answer_path(question_answer), notice: "Question sent for AI analysis"
    # else
    #   redirect_to question_answer_path(question_answer), alert: "Failed to send question for AI analysis"
    # end
  end
end
