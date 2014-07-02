class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_start_time

  def set_start_time
    @start_time = Time.now.usec
  end
end
