require 'spec_helper'

describe "when_dates/new" do
  before(:each) do
    assign(:when_date, stub_model(WhenDate).as_new_record)
  end

  it "renders new when_date form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => when_dates_path, :method => "post" do
    end
  end
end
