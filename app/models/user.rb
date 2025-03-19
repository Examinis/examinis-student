class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Relationship with contacts
  has_many :contacts, dependent: :destroy
  accepts_nested_attributes_for :contacts, reject_if: :all_blank, allow_destroy: true

  # Relationship with exams
  has_many :exams, dependent: :destroy

  before_create :set_default_role

  # Validations
  validates :first_name, :last_name, presence: true

  # Check if user is admin
  def admin?
    role == "admin"
  end

  private

  def set_default_role
    self.role ||= "student"
  end
end
