class WebcrawlsController < ApplicationController
  # GET /webcrawls
  # GET /webcrawls.json
  def index
    @webcrawls = Webcrawl.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @webcrawls }
    end
  end

  # GET /webcrawls/1
  # GET /webcrawls/1.json
  def show
    @webcrawl = Webcrawl.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @webcrawl }
    end
  end

  # GET /webcrawls/new
  # GET /webcrawls/new.json
  def new
    @webcrawl = Webcrawl.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @webcrawl }
    end
  end

  # GET /webcrawls/1/edit
  def edit
    @webcrawl = Webcrawl.find(params[:id])
  end

  # POST /webcrawls
  # POST /webcrawls.json
  def create
    @webcrawl = Webcrawl.new(params[:webcrawl])

    respond_to do |format|
      if @webcrawl.save
        format.html { redirect_to @webcrawl, notice: 'Webcrawl was successfully created.' }
        format.json { render json: @webcrawl, status: :created, location: @webcrawl }
      else
        format.html { render action: "new" }
        format.json { render json: @webcrawl.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /webcrawls/1
  # PUT /webcrawls/1.json
  def update
    @webcrawl = Webcrawl.find(params[:id])

    respond_to do |format|
      if @webcrawl.update_attributes(params[:webcrawl])
        format.html { redirect_to @webcrawl, notice: 'Webcrawl was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @webcrawl.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /webcrawls/1
  # DELETE /webcrawls/1.json
  def destroy
    @webcrawl = Webcrawl.find(params[:id])
    @webcrawl.destroy

    respond_to do |format|
      format.html { redirect_to webcrawls_url }
      format.json { head :no_content }
    end
  end
end
