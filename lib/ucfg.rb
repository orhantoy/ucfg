require "ucfg/version"
require "ostruct"

module Ucfg
  class Error < StandardError; end
  # Your code goes here...

  def self.validate(config, schema)
    # TODO: Actually implement this method to check the `config` against the `schema`
    OpenStruct.new(:valid? => true, :errors => [])
  end
end
