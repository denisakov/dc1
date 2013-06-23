require 'spec_helper'

describe "webcrawls/show" do
  before(:each) do
    @webcrawl = assign(:webcrawl, stub_model(Webcrawl,
      :html => "MyText",
      :retries => 1,
      :status_code => 2,
      :url => "MyText",
      :project_id => 3
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/MyText/)
    rendered.should match(/1/)
    rendered.should match(/2/)
    rendered.should match(/MyText/)
    rendered.should match(/3/)
  end
end
