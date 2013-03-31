require "spec_helper"

describe StandardsController do
  describe "routing" do

    it "routes to #index" do
      get("/standards").should route_to("standards#index")
    end

    it "routes to #new" do
      get("/standards/new").should route_to("standards#new")
    end

    it "routes to #show" do
      get("/standards/1").should route_to("standards#show", :id => "1")
    end

    it "routes to #edit" do
      get("/standards/1/edit").should route_to("standards#edit", :id => "1")
    end

    it "routes to #create" do
      post("/standards").should route_to("standards#create")
    end

    it "routes to #update" do
      put("/standards/1").should route_to("standards#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/standards/1").should route_to("standards#destroy", :id => "1")
    end

  end
end
