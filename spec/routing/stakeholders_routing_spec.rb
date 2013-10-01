require "spec_helper"

describe StakeholdersController do
  describe "routing" do

    it "routes to #index" do
      get("/stakeholders").should route_to("stakeholders#index")
    end

    it "routes to #new" do
      get("/stakeholders/new").should route_to("stakeholders#new")
    end

    it "routes to #show" do
      get("/stakeholders/1").should route_to("stakeholders#show", :id => "1")
    end

    it "routes to #edit" do
      get("/stakeholders/1/edit").should route_to("stakeholders#edit", :id => "1")
    end

    it "routes to #create" do
      post("/stakeholders").should route_to("stakeholders#create")
    end

    it "routes to #update" do
      put("/stakeholders/1").should route_to("stakeholders#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/stakeholders/1").should route_to("stakeholders#destroy", :id => "1")
    end

  end
end
