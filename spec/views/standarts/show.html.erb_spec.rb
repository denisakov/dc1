require 'spec_helper'

describe "standarts/show" do
  before(:each) do
    @standart = assign(:standart, stub_model(Standart,
      :name => "Name",
      :project_id => nil
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(//)
  end
end
