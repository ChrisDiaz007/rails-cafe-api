class Cafe < ApplicationRecord
  # cafe.rb
  validates :title, presence: true, uniqueness: { scope: :address }
  validates :address, presence: true
end
