require 'spec_helper'

describe "schemes/new" do
  before(:each) do
    assign(:scheme, stub_model(Scheme,
      :desc => "MyText"
    ).as_new_record)
  end

  it "renders new scheme form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => schemes_path, :method => "post" do
      assert_select "textarea#scheme_desc", :name => "scheme[desc]"
    end
  end
end
