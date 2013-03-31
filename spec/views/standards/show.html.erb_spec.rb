require 'spec_helper'

describe "standards/show" do
  before(:each) do
    @standard = assign(:standard, stub_model(Standard,
      :name => "Name",
      :project_id => ""
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(//)
  end
end
