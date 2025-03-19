class Exam < ApplicationRecord
  belongs_to :user
  belongs_to :teacher
  belongs_to :subject

  has_many :exam_questions, dependent: :destroy
  has_many :questions, through: :exam_questions
  has_many :user_answers, dependent: :destroy
end
