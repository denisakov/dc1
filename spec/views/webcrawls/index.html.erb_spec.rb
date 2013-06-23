require 'spec_helper'

describe "webcrawls/index" do
  before(:each) do
    assign(:webcrawls, [
      stub_model(Webcrawl,
        :html => "MyText",
        :retries => 1,
        :status_code => 2,
        :url => "MyText",
        :project_id => 3
      ),
      stub_model(Webcrawl,
        :html => "MyText",
        :retries => 1,
        :status_code => 2,
        :url => "MyText",
        :project_id => 3
      )
    ])
  end

  it "renders a list of webcrawls" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => 3.to_s, :count => 2
  end
end
