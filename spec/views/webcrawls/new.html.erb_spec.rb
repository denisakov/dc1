require 'spec_helper'

describe "webcrawls/new" do
  before(:each) do
    assign(:webcrawl, stub_model(Webcrawl,
      :html => "MyText",
      :retries => 1,
      :status_code => 1,
      :url => "MyText",
      :project_id => 1
    ).as_new_record)
  end

  it "renders new webcrawl form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => webcrawls_path, :method => "post" do
      assert_select "textarea#webcrawl_html", :name => "webcrawl[html]"
      assert_select "input#webcrawl_retries", :name => "webcrawl[retries]"
      assert_select "input#webcrawl_status_code", :name => "webcrawl[status_code]"
      assert_select "textarea#webcrawl_url", :name => "webcrawl[url]"
      assert_select "input#webcrawl_project_id", :name => "webcrawl[project_id]"
    end
  end
end
