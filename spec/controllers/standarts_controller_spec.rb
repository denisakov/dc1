require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe StandartsController do

  # This should return the minimal set of attributes required to create a valid
  # Standart. As you add validations to Standart, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {}
  end
  
  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # StandartsController. Be sure to keep this updated too.
  def valid_session
    {}
  end

  describe "GET index" do
    it "assigns all standarts as @standarts" do
      standart = Standart.create! valid_attributes
      get :index, {}, valid_session
      assigns(:standarts).should eq([standart])
    end
  end

  describe "GET show" do
    it "assigns the requested standart as @standart" do
      standart = Standart.create! valid_attributes
      get :show, {:id => standart.to_param}, valid_session
      assigns(:standart).should eq(standart)
    end
  end

  describe "GET new" do
    it "assigns a new standart as @standart" do
      get :new, {}, valid_session
      assigns(:standart).should be_a_new(Standart)
    end
  end

  describe "GET edit" do
    it "assigns the requested standart as @standart" do
      standart = Standart.create! valid_attributes
      get :edit, {:id => standart.to_param}, valid_session
      assigns(:standart).should eq(standart)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Standart" do
        expect {
          post :create, {:standart => valid_attributes}, valid_session
        }.to change(Standart, :count).by(1)
      end

      it "assigns a newly created standart as @standart" do
        post :create, {:standart => valid_attributes}, valid_session
        assigns(:standart).should be_a(Standart)
        assigns(:standart).should be_persisted
      end

      it "redirects to the created standart" do
        post :create, {:standart => valid_attributes}, valid_session
        response.should redirect_to(Standart.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved standart as @standart" do
        # Trigger the behavior that occurs when invalid params are submitted
        Standart.any_instance.stub(:save).and_return(false)
        post :create, {:standart => {}}, valid_session
        assigns(:standart).should be_a_new(Standart)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Standart.any_instance.stub(:save).and_return(false)
        post :create, {:standart => {}}, valid_session
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested standart" do
        standart = Standart.create! valid_attributes
        # Assuming there are no other standarts in the database, this
        # specifies that the Standart created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Standart.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, {:id => standart.to_param, :standart => {'these' => 'params'}}, valid_session
      end

      it "assigns the requested standart as @standart" do
        standart = Standart.create! valid_attributes
        put :update, {:id => standart.to_param, :standart => valid_attributes}, valid_session
        assigns(:standart).should eq(standart)
      end

      it "redirects to the standart" do
        standart = Standart.create! valid_attributes
        put :update, {:id => standart.to_param, :standart => valid_attributes}, valid_session
        response.should redirect_to(standart)
      end
    end

    describe "with invalid params" do
      it "assigns the standart as @standart" do
        standart = Standart.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Standart.any_instance.stub(:save).and_return(false)
        put :update, {:id => standart.to_param, :standart => {}}, valid_session
        assigns(:standart).should eq(standart)
      end

      it "re-renders the 'edit' template" do
        standart = Standart.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Standart.any_instance.stub(:save).and_return(false)
        put :update, {:id => standart.to_param, :standart => {}}, valid_session
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested standart" do
      standart = Standart.create! valid_attributes
      expect {
        delete :destroy, {:id => standart.to_param}, valid_session
      }.to change(Standart, :count).by(-1)
    end

    it "redirects to the standarts list" do
      standart = Standart.create! valid_attributes
      delete :destroy, {:id => standart.to_param}, valid_session
      response.should redirect_to(standarts_url)
    end
  end

end
