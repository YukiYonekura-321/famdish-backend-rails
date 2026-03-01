class Suggestion < ApplicationRecord
  belongs_to :family, optional: true
  has_many :recipes, dependent: :nullify
end