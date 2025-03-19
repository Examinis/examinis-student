class ExamApiService
  def self.connection
    @connection ||= Faraday.new(url: ENV.fetch("API_URL", "http://localhost:8000/api")) do |faraday|
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
      Rails.logger.error("Failed to fetch exam #{id}: HTTP #{response.status}")
      { "success" => false, "message" => "Failed to fetch exam", "exam_id" => id }
    end
  end

  def self.submit_exam(exam_id, payload)
    response = connection.post("/exams/#{exam_id}/grade") do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = payload.to_json
    end

    if response.status == 200
      JSON.parse(response.body)
    else
      Rails.logger.error("Failed to submit exam #{exam_id}: HTTP #{response.status}")
      { "success" => false, "message" => "Failed to submit exam", "exam_id" => exam_id }
    end
  end
end
