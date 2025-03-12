class Contact < ApplicationRecord
  belongs_to :user

  # Enum to define the contact type
  enum :contact_type, [ :whatsapp, :phone, :instagram, :telegram, :linkedin ]

  validates :value, presence: true
  validates :contact_type, presence: true

  private

  # Validates the format of the contact value based on the contact type.
  #
  # For 'phone' and 'whatsapp' contact types, the value must contain 10 or 11 digits.
  # For 'instagram' contact type, the value must be a valid Instagram username (1 to 30 characters,
  # consisting of letters, numbers, underscores, and periods, optionally starting with '@').
  #
  # If the value does not meet the criteria, an error is added to the :value attribute.
  #
  # @return [void]
  def validate_contact_format
    case contact_type
    when "phone", "whatsapp"
      unless value.gsub(/\D/, "").match?(/\A\d{10,11}\z/)
        errors.add(:value, "deve ter 10 ou 11 dígitos")
      end
    when "instagram"
      unless value.gsub(/\s/, "").match?(/\A@?[a-zA-Z0-9_.]{1,30}\z/)
        errors.add(:value, "não é um nome de usuário válido do Instagram")
      end
    end
  end

  # Returns an array with the contact types for the select input.
  def self.contact_types_for_select
    contact_types.keys.map { |type| [ type.capitalize, type ] }
  end
end
