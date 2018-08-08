require 'mongoid'

class Transaction
  include Mongoid::Document

  field :chat_id, type: String
  field :message_id, type: Integer
  field :message, type: String
  field :timestamp, type: DateTime
  field :amount, type: Float
  field :description, type: String
  include Mongoid::Timestamps

  belongs_to :user
  has_and_belongs_to_many :categories

  index({ chat_id: 1, message_id: 1 }, { unique: true })

  def to_s
    hashtags = categories.map { |c| "#%s" % c.slug }

    "%.2f %s %s" % [
      amount,
      description,
      hashtags.join(' ')
    ]
  end
end
