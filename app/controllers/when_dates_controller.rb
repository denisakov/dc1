class WhenDatesController < ApplicationController
  helper_method :sort_column, :sort_direction
  # GET /when_dates
  # GET /when_dates.json
  def index
    @when_dates = WhenDate.scoped.order(sort_column + " " + sort_direction).page(params[:page]).per_page(50)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @when_dates }
    end
  end

  # GET /when_dates/1
  # GET /when_dates/1.json
  def show
    @when_date = WhenDate.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @when_date }
    end
  end

  # GET /when_dates/new
  # GET /when_dates/new.json
  def new
    @when_date = WhenDate.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @when_date }
    end
  end

  # GET /when_dates/1/edit
  def edit
    @when_date = WhenDate.find(params[:id])
  end

  # POST /when_dates
  # POST /when_dates.json
  def create
    @when_date = WhenDate.new(params[:when_date])

    respond_to do |format|
      if @when_date.save
        format.html { redirect_to @when_date, notice: 'When date was successfully created.' }
        format.json { render json: @when_date, status: :created, location: @when_date }
      else
        format.html { render action: "new" }
        format.json { render json: @when_date.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /when_dates/1
  # PUT /when_dates/1.json
  def update
    @when_date = WhenDate.find(params[:id])

    respond_to do |format|
      if @when_date.update_attributes(params[:when_date])
        format.html { redirect_to @when_date, notice: 'When date was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @when_date.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /when_dates/1
  # DELETE /when_dates/1.json
  def destroy
    @when_date = WhenDate.find(params[:id])
    @when_date.destroy

    respond_to do |format|
      format.html { redirect_to when_dates_url }
      format.json { head :no_content }
    end
  end

  private

  def sort_column
    WhenDate.joins(:documents).column_names.include?(params[:sort]) ? params[:sort] : "date"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end

end
