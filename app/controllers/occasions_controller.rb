class OccasionsController < ApplicationController
  helper_method :sort_column, :sort_direction
  # GET /occasions
  # GET /occasions.json
  def index
    @occasions = Occasion.joins{:when_dates}.order(sort_column + " " + sort_direction).paginate(:page => params[:page], :per_page => 30)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @occasions }
    end
  end

  # GET /occasions/1
  # GET /occasions/1.json
  def show
    @occasion = Occasion.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @occasion }
    end
  end

  # GET /occasions/new
  # GET /occasions/new.json
  def new
    @occasion = Occasion.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @occasion }
    end
  end

  # GET /occasions/1/edit
  def edit
    @occasion = Occasion.find(params[:id])
  end

  # POST /occasions
  # POST /occasions.json
  def create
    @occasion = Occasion.new(params[:occasion])

    respond_to do |format|
      if @occasion.save
        format.html { redirect_to @occasion, notice: 'Occasion was successfully created.' }
        format.json { render json: @occasion, status: :created, location: @occasion }
      else
        format.html { render action: "new" }
        format.json { render json: @occasion.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /occasions/1
  # PUT /occasions/1.json
  def update
    @occasion = Occasion.find(params[:id])

    respond_to do |format|
      if @occasion.update_attributes(params[:occasion])
        format.html { redirect_to @occasion, notice: 'Occasion was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @occasion.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /occasions/1
  # DELETE /occasions/1.json
  def destroy
    @occasion = Occasion.find(params[:id])
    @occasion.destroy

    respond_to do |format|
      format.html { redirect_to occasions_url }
      format.json { head :no_content }
    end
  end

private

  def sort_column
    Occasion.joins{:when_dates}.column_names.include?(params[:sort]) ? params[:sort] : "id"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end

end
