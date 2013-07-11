require "spec_helper"

describe WhenDatesController do
  describe "routing" do

    it "routes to #index" do
      get("/when_dates").should route_to("when_dates#index")
    end

    it "routes to #new" do
      get("/when_dates/new").should route_to("when_dates#new")
    end

    it "routes to #show" do
      get("/when_dates/1").should route_to("when_dates#show", :id => "1")
    end

    it "routes to #edit" do
      get("/when_dates/1/edit").should route_to("when_dates#edit", :id => "1")
    end

    it "routes to #create" do
      post("/when_dates").should route_to("when_dates#create")
    end

    it "routes to #update" do
      put("/when_dates/1").should route_to("when_dates#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/when_dates/1").should route_to("when_dates#destroy", :id => "1")
    end

  end
end
