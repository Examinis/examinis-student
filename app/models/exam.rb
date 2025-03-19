class Exam < ApplicationRecord
  belongs_to :teacher
  belongs_to :subject
  has_many :questions, dependent: :destroy
end
