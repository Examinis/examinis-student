class UserAnswer < ApplicationRecord
  belongs_to :user
  belongs_to :question
  belongs_to :option
  belongs_to :exam

  validates :user_id, uniqueness: { scope: [ :question_id, :exam_id ],
                                    message: "já respondeu esta questão neste exame" }
end
