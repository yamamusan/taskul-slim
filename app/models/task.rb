class Task < ApplicationRecord
  attr_accessor :statuses, :priorities

  enum priority: { normal: 0, low: -1, high: 1 }, _prefix: true
  enum status: { todo: 0, doing: 1, done: 2 }, _prefix: true

  validates :title, presence: true, length: { maximum: 256 }
  validates :status, presence: true
  validate :not_before_today

  scope :title_like, ->(title) { where('title like ?', "%#{title}%") if title.present? }
  scope :description_like, ->(description) { where('description like ?', "%#{description}%") if description.present? }
  scope :status_in, ->(statuses) { where(status: statuses) if statuses.present?}
  scope :priority_in, ->(priorities) { where(priority: priorities) if priorities.present?}

  def search
    Task.title_like(title).description_like(description).status_in(statuses).priority_in(priorities)
  end

  def not_before_today
    errors.add(:due_date, :not_before_today) if due_date.present? && due_date < Date.today
  end
end
