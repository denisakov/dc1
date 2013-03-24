require "spec_helper"

describe StandartsController do
  describe "routing" do

    it "routes to #index" do
      get("/standarts").should route_to("standarts#index")
    end

    it "routes to #new" do
      get("/standarts/new").should route_to("standarts#new")
    end

    it "routes to #show" do
      get("/standarts/1").should route_to("standarts#show", :id => "1")
    end

    it "routes to #edit" do
      get("/standarts/1/edit").should route_to("standarts#edit", :id => "1")
    end

    it "routes to #create" do
      post("/standarts").should route_to("standarts#create")
    end

    it "routes to #update" do
      put("/standarts/1").should route_to("standarts#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/standarts/1").should route_to("standarts#destroy", :id => "1")
    end

  end
end
