class Question < ApplicationRecord
  belongs_to :exam
  has_many :options, dependent: :destroy
end
