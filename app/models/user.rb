require 'mongoid'

class User
  include Mongoid::Document
  field :_id, type: Integer
  field :username, type: String
  field :first_name, type: String
  field :last_name, type: String
  include Mongoid::Timestamps
end
