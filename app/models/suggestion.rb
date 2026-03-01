class Suggestion < ApplicationRecord
  belongs_to :family, optional: true
end