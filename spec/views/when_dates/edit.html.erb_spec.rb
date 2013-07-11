require 'spec_helper'

describe "when_dates/edit" do
  before(:each) do
    @when_date = assign(:when_date, stub_model(WhenDate))
  end

  it "renders the edit when_date form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => when_dates_path(@when_date), :method => "post" do
    end
  end
end
