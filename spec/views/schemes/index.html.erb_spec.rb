require 'spec_helper'

describe "schemes/index" do
  before(:each) do
    assign(:schemes, [
      stub_model(Scheme,
        :desc => "MyText"
      ),
      stub_model(Scheme,
        :desc => "MyText"
      )
    ])
  end

  it "renders a list of schemes" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end
