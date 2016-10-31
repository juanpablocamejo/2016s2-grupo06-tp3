class MongoDB
  @@client = nil

  # @return [Mongo::Client]
  def self.client
    if @@client.nil?
      @@client = Mongo::Client.new(['127.0.0.1:27017'], :database => 'test')
    end
    @@client
  end
end