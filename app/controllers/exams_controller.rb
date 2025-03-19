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
      # Buscar o ID externo do exame (da API)
      external_exam_id = response_data["id"] || response_data["exam_id"]
      Rails.logger.info "Salvando exame com ID externo: #{external_exam_id} para o usuário #{user.id}"

      teacher = Teacher.find_or_create_by(id: response_data["teacher"]["id"]) do |t|
        t.first_name = response_data["teacher"]["first_name"]
        t.last_name = response_data["teacher"]["last_name"]
      end

      subject = Subject.find_or_create_by(id: response_data["subject"]["id"]) do |s|
        s.name = response_data["subject"]["name"]
      end

      # Procurar ou criar o exame, armazenando o ID externo
      exam = Exam.find_or_create_by(
        user: user,
        external_id: external_exam_id
      ) do |e|
        e.title = response_data["title"]
        e.instructions = response_data["instructions"]
        e.teacher = teacher
        e.subject = subject
      end

      # Atualizar os campos que podem mudar
      exam.update!(
        answered_at: response_data["answered_at"],
        score: response_data["score"]
      )

      # Limpar respostas existentes para evitar duplicatas
      UserAnswer.where(user: user, exam: exam).destroy_all
      Rails.logger.info "Respostas anteriores removidas para o exame ID=#{exam.id}"

      # Salvar as questões e respostas
      response_data["questions"].each do |question_data|
        question = Question.find_or_create_by(id: question_data["id"]) do |q|
          q.text = question_data["text"]
        end

        # Garantir que a relação entre exame e questão existe
        exam.exam_questions.find_or_create_by!(question: question)

        # Verificar qual opção foi selecionada
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
            Rails.logger.info "Opção selecionada: Q#{question.id}, O#{option.id} para Exame #{exam.id}"
          end
        end

        # Salvar a resposta do usuário se uma opção foi selecionada
        if selected_option
          user_answer = UserAnswer.create!(
            user: user,
            question: question,
            option: selected_option,
            exam: exam
          )
          Rails.logger.info "UserAnswer criada: ID=#{user_answer.id}, User=#{user.id}, Exam=#{exam.id}, Q=#{question.id}, O=#{selected_option.id}"
        else
          Rails.logger.info "Nenhuma opção selecionada para Q#{question.id}"
        end
      end

      # Verificação final
      answer_count = UserAnswer.where(user: user, exam: exam).count
      Rails.logger.info "Exame salvo com sucesso. ID=#{exam.id}, Respostas: #{answer_count}"

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
