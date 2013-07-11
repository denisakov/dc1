require 'spec_helper'

describe "occasions/edit" do
  before(:each) do
    @occasion = assign(:occasion, stub_model(Occasion,
      :description => "MyText"
    ))
  end

  it "renders the edit occasion form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => occasions_path(@occasion), :method => "post" do
      assert_select "textarea#occasion_description", :name => "occasion[description]"
    end
  end
end
