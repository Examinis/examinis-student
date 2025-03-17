# app/controllers/exams_controller.rb
class ExamsController < ApplicationController
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
end
