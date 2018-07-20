require 'mongoid'

class Transaction
  include Mongoid::Document

  field :message_id, type: Integer
  field :message, type: String
  field :timestamp, type: DateTime
  field :amount, type: Float
  field :description, type: String
  include Mongoid::Timestamps

  belongs_to :user
end
