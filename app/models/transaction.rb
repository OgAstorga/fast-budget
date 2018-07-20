require 'mongoid'

class Transaction
  include Mongoid::Document

  field :chat_id, type: Integer
  field :message_id, type: Integer
  field :message, type: String
  field :timestamp, type: DateTime
  field :amount, type: Float
  field :description, type: String
  include Mongoid::Timestamps

  belongs_to :user

  index({ chat_id: 1, message_id: 1 }, { unique: true })
end
