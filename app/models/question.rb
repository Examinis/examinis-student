class Question < ApplicationRecord
  has_many :exam_questions, dependent: :destroy
  has_many :exams, through: :exam_questions

  has_many :options, dependent: :destroy
end
