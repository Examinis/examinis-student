class HomeController < ApplicationController
  def index
    conn = Faraday.new(url: "http://172.22.0.3:8000/api") do |faraday|
      faraday.adapter Faraday.default_adapter
      # faraday.headers["Content-Type"] = "application/json"
    end

    response = conn.get("/exams/1")
    puts response.body
  end
end
