require 'spec_helper'

describe "when_dates/show" do
  before(:each) do
    @when_date = assign(:when_date, stub_model(WhenDate))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
