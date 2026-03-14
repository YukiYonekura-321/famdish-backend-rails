class Suggestion < ApplicationRecord
  belongs_to :family, optional: true
  has_many :recipes, dependent: :nullify

  # status: pending → processing → completed / failed
  validates :status, inclusion: { in: %w[pending processing completed failed] }

  def completed? = status == "completed"
  def failed?    = status == "failed"
  def pending?   = status == "pending"
end
