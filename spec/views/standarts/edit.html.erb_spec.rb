require 'spec_helper'

describe "standards/edit" do
  before(:each) do
    @standard = assign(:standard, stub_model(standard,
      :name => "MyString",
      :project_id => nil
    ))
  end

  it "renders the edit standard form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => standards_path(@standard), :method => "post" do
      assert_select "input#standard_name", :name => "standard[name]"
      assert_select "input#standard_project_id", :name => "standard[project_id]"
    end
  end
end
