require 'spec_helper'

describe "schemes/show" do
  before(:each) do
    @scheme = assign(:scheme, stub_model(Scheme,
      :desc => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/MyText/)
  end
end
