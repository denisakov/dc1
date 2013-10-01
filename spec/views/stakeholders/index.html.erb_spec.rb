require 'spec_helper'

describe "stakeholders/index" do
  before(:each) do
    assign(:stakeholders, [
      stub_model(Stakeholder,
        :title => "Title",
        :short_title => "Short Title"
      ),
      stub_model(Stakeholder,
        :title => "Title",
        :short_title => "Short Title"
      )
    ])
  end

  it "renders a list of stakeholders" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Title".to_s, :count => 2
    assert_select "tr>td", :text => "Short Title".to_s, :count => 2
  end
end
