require 'spec_helper'

describe "when_dates/index" do
  before(:each) do
    assign(:when_dates, [
      stub_model(WhenDate),
      stub_model(WhenDate)
    ])
  end

  it "renders a list of when_dates" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
