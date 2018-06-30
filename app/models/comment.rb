class Comment < ApplicationRecord
  belongs_to :task

  validates :contents, presence: true, length: { maximum: 256 }
end
