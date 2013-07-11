require 'spec_helper'

describe "occasions/show" do
  before(:each) do
    @occasion = assign(:occasion, stub_model(Occasion,
      :description => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/MyText/)
  end
end
