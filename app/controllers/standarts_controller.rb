class StandartsController < ApplicationController
  # GET /standarts
  # GET /standarts.json
  def index
    @standarts = Standart.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @standarts }
    end
  end

  # GET /standarts/1
  # GET /standarts/1.json
  def show
    @standart = Standart.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @standart }
    end
  end

  # GET /standarts/new
  # GET /standarts/new.json
  def new
    @standart = Standart.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @standart }
    end
  end

  # GET /standarts/1/edit
  def edit
    @standart = Standart.find(params[:id])
  end

  # POST /standarts
  # POST /standarts.json
  def create
    @standart = Standart.new(params[:standart])

    respond_to do |format|
      if @standart.save
        format.html { redirect_to @standart, notice: 'Standart was successfully created.' }
        format.json { render json: @standart, status: :created, location: @standart }
      else
        format.html { render action: "new" }
        format.json { render json: @standart.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /standarts/1
  # PUT /standarts/1.json
  def update
    @standart = Standart.find(params[:id])

    respond_to do |format|
      if @standart.update_attributes(params[:standart])
        format.html { redirect_to @standart, notice: 'Standart was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @standart.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /standarts/1
  # DELETE /standarts/1.json
  def destroy
    @standart = Standart.find(params[:id])
    @standart.destroy

    respond_to do |format|
      format.html { redirect_to standarts_url }
      format.json { head :no_content }
    end
  end
end
