# app/controllers/exams_controller.rb
class ExamsController < ApplicationController
  before_action :authenticate_user!

  # GET /exams
  def index
    @page = (params[:page] || 1).to_i
    @size = (params[:size] || 9).to_i
    response = ExamApiService.get_exams(page: @page, size: @size)

    @exams = response["results"] || []
    @total = response["total"].to_i || 0

    @paginated_exams = Kaminari.paginate_array(
      @exams,
      total_count: @total
    ).page(@page).per(@size)
  end

  # GET /exams/:id
  def show
    exam_id = params[:id]
    @exam = ExamApiService.get_exam(exam_id)

    if @exam.nil?
      flash[:alert] = "Prova não encontrada"
      redirect_to exams_path
    end
  end

  # POST /exams/:id/submit
  def submit
    exam_id = params[:id]
    answers = params[:answers].to_unsafe_h || {}
    user = current_user
    puts current_user

    payload = {
      answers: answers.map { |question_id, option_id| { question_id: question_id.to_i, selected_option: option_id.to_i } }
    }

    response = ExamApiService.submit_exam(exam_id, payload)

    if response["title"]
      save_exam(response, user)
      flash[:notice] = "Respostas enviadas com sucesso!"
    else
      flash[:alert] = "Erro ao enviar respostas."
    end

    redirect_to exams_path
  end

  def save_exam(response_data, user)
    ActiveRecord::Base.transaction do
      teacher = Teacher.find_or_create_by(id: response_data["teacher"]["id"]) do |t|
        t.first_name = response_data["teacher"]["first_name"]
        t.last_name = response_data["teacher"]["last_name"]
      end

      subject = Subject.find_or_create_by(id: response_data["subject"]["id"]) do |s|
        s.name = response_data["subject"]["name"]
      end

      exam = Exam.create!(
        title: response_data["title"],
        instructions: response_data["instructions"],
        answered_at: response_data["answered_at"],
        score: response_data["score"],
        teacher: teacher,
        subject: subject,
        user: user
      )

      response_data["questions"].each do |question_data|
        question = exam.questions.create!(
          id: question_data["id"],
          text: question_data["text"]
        )

        question_data["options"].each do |option_data|
          question.options.create!(
            id: option_data["id"],
            description: option_data["description"],
            letter: option_data["letter"],
            is_correct: option_data["is_correct"],
            selected: option_data["selected"]
          )
        end
      end

      exam
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Erro ao salvar exame: #{e.message}"
    nil
  end

  def answered
    @answered_exams = Exam.where(user: current_user).order(answered_at: :desc)
  end

  def answered_show
    @exam = Exam.includes(questions: :options).find_by(id: params[:id], user: current_user)

    if @exam.nil?
      flash[:alert] = "Exame não encontrado."
      redirect_to answered_exams_path
    end
  end
end
