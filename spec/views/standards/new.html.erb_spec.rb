require 'spec_helper'

describe "standards/new" do
  before(:each) do
    assign(:standard, stub_model(Standard,
      :name => "MyString",
      :project_id => ""
    ).as_new_record)
  end

  it "renders new standard form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => standards_path, :method => "post" do
      assert_select "input#standard_name", :name => "standard[name]"
      assert_select "input#standard_project_id", :name => "standard[project_id]"
    end
  end
end
