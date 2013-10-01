require 'spec_helper'

describe "stakeholders/show" do
  before(:each) do
    @stakeholder = assign(:stakeholder, stub_model(Stakeholder,
      :title => "Title",
      :short_title => "Short Title"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Title/)
    rendered.should match(/Short Title/)
  end
end
