require 'spec_helper'

describe "Webcrawls" do
  describe "GET /webcrawls" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get webcrawls_path
      response.status.should be(200)
    end
  end
end
