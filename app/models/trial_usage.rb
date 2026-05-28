class TrialUsage < ApplicationRecord
  TRIAL_LIMIT = 2

  validates :firebase_uid, presence: true, uniqueness: true
  validates :usage_count, numericality: { greater_than_or_equal_to: 0 }

  def self.find_or_initialize_for(firebase_uid)
    find_or_initialize_by(firebase_uid: firebase_uid)
  end

  def limit_exceeded?
    usage_count >= TRIAL_LIMIT
  end

  def increment!
    update!(usage_count: usage_count + 1)
  end
end
