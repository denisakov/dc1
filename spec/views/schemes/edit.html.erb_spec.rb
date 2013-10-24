require 'spec_helper'

describe "schemes/edit" do
  before(:each) do
    @scheme = assign(:scheme, stub_model(Scheme,
      :desc => "MyText"
    ))
  end

  it "renders the edit scheme form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => schemes_path(@scheme), :method => "post" do
      assert_select "textarea#scheme_desc", :name => "scheme[desc]"
    end
  end
end
