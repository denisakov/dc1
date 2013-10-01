require 'spec_helper'

describe "stakeholders/new" do
  before(:each) do
    assign(:stakeholder, stub_model(Stakeholder,
      :title => "MyString",
      :short_title => "MyString"
    ).as_new_record)
  end

  it "renders new stakeholder form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => stakeholders_path, :method => "post" do
      assert_select "input#stakeholder_title", :name => "stakeholder[title]"
      assert_select "input#stakeholder_short_title", :name => "stakeholder[short_title]"
    end
  end
end
