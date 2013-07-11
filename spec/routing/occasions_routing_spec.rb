require "spec_helper"

describe OccasionsController do
  describe "routing" do

    it "routes to #index" do
      get("/occasions").should route_to("occasions#index")
    end

    it "routes to #new" do
      get("/occasions/new").should route_to("occasions#new")
    end

    it "routes to #show" do
      get("/occasions/1").should route_to("occasions#show", :id => "1")
    end

    it "routes to #edit" do
      get("/occasions/1/edit").should route_to("occasions#edit", :id => "1")
    end

    it "routes to #create" do
      post("/occasions").should route_to("occasions#create")
    end

    it "routes to #update" do
      put("/occasions/1").should route_to("occasions#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/occasions/1").should route_to("occasions#destroy", :id => "1")
    end

  end
end
