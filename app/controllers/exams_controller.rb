# app/controllers/exams_controller.rb
class ExamsController < ApplicationController
  def index
    @page = (params[:page] || 1).to_i
    @size = (params[:size] || 10).to_i

    response = ExamApiService.get_exams(page: @page, size: @size)

    @exams = response["results"]
    puts "EXAMS -----> #{@exams}"
    @total = response["total"].to_i

    # Adapta os dados para o formato que o Kaminari espera
    @paginated_exams = Kaminari.paginate_array(
      @exams,
      total_count: @total
    ).page(@page).per(@size)
  end
end
