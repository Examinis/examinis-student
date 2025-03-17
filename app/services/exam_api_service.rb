class ExamApiService
  def self.connection
    @connection ||= Faraday.new(url: "http://172.21.0.3:8000/api") do |faraday|
      faraday.headers["Accept"] = "application/json"
      faraday.adapter Faraday.default_adapter
    end
  end

  def self.get_exams(page: 1, size: 10)
    response = connection.get("/exams/", { page: page, size: size })
    if response.status == 200
      JSON.parse(response.body)
    else
      { "results" => [], "total" => 0, "page" => page, "size" => size }
    end
  end

  def self.get_exam(id)
    response = connection.get("/exams/#{id}")
    if response.status == 200
      JSON.parse(response.body)
    else
      puts "Erro ao buscar prova"
    end
  end
end
