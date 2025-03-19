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
      # Pegar o ID externo do exame da API
      external_exam_id = response_data["id"] || response_data["exam_id"]

      teacher = Teacher.find_or_create_by(id: response_data["teacher"]["id"]) do |t|
        t.first_name = response_data["teacher"]["first_name"]
        t.last_name = response_data["teacher"]["last_name"]
      end

      subject = Subject.find_or_create_by(id: response_data["subject"]["id"]) do |s|
        s.name = response_data["subject"]["name"]
      end

      # Sempre criar um novo exame para cada resposta do usuário
      # Usamos o timestamp atual para garantir um registro único
      exam = Exam.create!(
        title: response_data["title"],
        instructions: response_data["instructions"],
        answered_at: response_data["answered_at"] || Time.current,
        score: response_data["score"],
        external_id: external_exam_id,
        teacher: teacher,
        subject: subject,
        user: user
      )

      response_data["questions"].each do |question_data|
        question = Question.find_or_create_by(id: question_data["id"]) do |q|
          q.text = question_data["text"]
        end

        # Criar a relação entre exame e questão
        exam.exam_questions.create!(question: question)

        # Verificar qual opção foi selecionada pelo usuário
        selected_option = nil

        question_data["options"].each do |option_data|
          option = question.options.find_or_create_by!(id: option_data["id"]) do |opt|
            opt.description = option_data["description"]
            opt.letter = option_data["letter"]
            opt.is_correct = option_data["is_correct"]
          end

          # Verificar se esta opção foi selecionada
          if option_data["selected"]
            selected_option = option
          end
        end

        # Salvar a resposta do usuário se uma opção foi selecionada
        if selected_option
          UserAnswer.create!(
            user: user,
            question: question,
            option: selected_option,
            exam: exam
          )
        end
      end

      exam
    end
  rescue ActiveRecord::RecordInvalid => e
    nil
  end



  def answered
    @answered_exams = Exam.where(user: current_user)
                          .includes(:subject, :teacher)
                          .order(answered_at: :desc)
  end

  def answered_show
    @exam = Exam.includes(questions: :options).find_by(id: params[:id], user: current_user)

    if @exam.nil?
      flash[:alert] = "Exame não encontrado."
      redirect_to answered_exams_path
      return
    end

    Rails.logger.info "Buscando respostas para o exame ID=#{@exam.id}, User=#{current_user.id}"

    # Buscar todas as respostas do usuário para este exame específico
    @user_answers = UserAnswer.where(
      user_id: current_user.id,
      exam_id: @exam.id
    ).includes(:question, :option)

    Rails.logger.info "Encontradas #{@user_answers.count} respostas para o exame #{@exam.id}"

    # Para depuração: verificar as questões do exame vs. as respostas encontradas
    exam_question_ids = @exam.questions.pluck(:id)
    Rails.logger.debug "IDs das questões do exame: #{exam_question_ids.join(', ')}"

    answer_question_ids = @user_answers.pluck(:question_id)
    Rails.logger.debug "IDs das questões com respostas: #{answer_question_ids.join(', ')}"

    # Indexar por question_id para fácil acesso na view
    @user_answers = @user_answers.index_by(&:question_id)
  end
end
