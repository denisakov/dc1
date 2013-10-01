require 'spec_helper'

describe "entities/index" do
  before(:each) do
    assign(:entities, [
      stub_model(Entity,
        :role => "Role"
      ),
      stub_model(Entity,
        :role => "Role"
      )
    ])
  end

  it "renders a list of entities" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Role".to_s, :count => 2
  end
end
