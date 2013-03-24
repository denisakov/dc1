require 'spec_helper'

describe "standarts/new" do
  before(:each) do
    assign(:standart, stub_model(Standart,
      :name => "MyString",
      :project_id => nil
    ).as_new_record)
  end

  it "renders new standart form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => standarts_path, :method => "post" do
      assert_select "input#standart_name", :name => "standart[name]"
      assert_select "input#standart_project_id", :name => "standart[project_id]"
    end
  end
end
