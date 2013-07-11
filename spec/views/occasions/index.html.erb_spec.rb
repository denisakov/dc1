require 'spec_helper'

describe "occasions/index" do
  before(:each) do
    assign(:occasions, [
      stub_model(Occasion,
        :description => "MyText"
      ),
      stub_model(Occasion,
        :description => "MyText"
      )
    ])
  end

  it "renders a list of occasions" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end
