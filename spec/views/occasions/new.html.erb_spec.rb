require 'spec_helper'

describe "occasions/new" do
  before(:each) do
    assign(:occasion, stub_model(Occasion,
      :description => "MyText"
    ).as_new_record)
  end

  it "renders new occasion form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => occasions_path, :method => "post" do
      assert_select "textarea#occasion_description", :name => "occasion[description]"
    end
  end
end
