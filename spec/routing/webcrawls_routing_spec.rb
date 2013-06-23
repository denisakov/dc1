require "spec_helper"

describe WebcrawlsController do
  describe "routing" do

    it "routes to #index" do
      get("/webcrawls").should route_to("webcrawls#index")
    end

    it "routes to #new" do
      get("/webcrawls/new").should route_to("webcrawls#new")
    end

    it "routes to #show" do
      get("/webcrawls/1").should route_to("webcrawls#show", :id => "1")
    end

    it "routes to #edit" do
      get("/webcrawls/1/edit").should route_to("webcrawls#edit", :id => "1")
    end

    it "routes to #create" do
      post("/webcrawls").should route_to("webcrawls#create")
    end

    it "routes to #update" do
      put("/webcrawls/1").should route_to("webcrawls#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/webcrawls/1").should route_to("webcrawls#destroy", :id => "1")
    end

  end
end
