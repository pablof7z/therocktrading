require 'spec_helper'

describe Therocktrading::API do
  subject(:ruby_gem) { Therocktrading::API.new }

  describe ".new" do
    it "makes a new instance" do
      expect(ruby_gem).to be_a Therocktrading::API
    end
  end
end
