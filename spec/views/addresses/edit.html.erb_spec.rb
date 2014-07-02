require 'spec_helper'

describe "addresses/edit" do
  before(:each) do
    @address = assign(:address, stub_model(Address,
      :text => ""
    ))
  end

  it "renders the edit address form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => addresses_path(@address), :method => "post" do
      assert_select "input#address_text", :name => "address[text]"
    end
  end
end
