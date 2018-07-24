require 'mongoid'

class Category
  include Mongoid::Document

  field :slug, type: String
  include Mongoid::Timestamps

  has_and_belongs_to_many :transactions

  index({ slug: 1 }, { unique: true })
end
