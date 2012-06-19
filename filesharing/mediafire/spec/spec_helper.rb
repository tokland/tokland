require 'rspec'
require 'mediafire'

module RspecExtensions
  def read_fixture(path)
    File.read(File.join(File.dirname(__FILE__), "fixtures", path))
  end
end

RSpec.configure do |config|
  config.include RspecExtensions
end
