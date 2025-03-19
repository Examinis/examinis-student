class Option < ApplicationRecord
  belongs_to :question
  has_many :user_answers, dependent: :destroy
end
