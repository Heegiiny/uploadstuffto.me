class ImagesController < ApplicationController
  before_action :set_image, only: [:show, :edit, :update, :destroy]
  before_filter :authenticate_user!,
                :only => [:edit, :update, :create, :edit_mode_submit, :destroy]
  include CanCreateNewAlbum

  # GET /images/key
  # GET /images/key.json
  def show
    @permissions = {
      :edit => (user_signed_in? && @image.is_owned_by_user?(current_user))
    }
  end

  # GET /images/key/edit
  def edit
    @image = Image.find_by_key(params[:key])

    if current_user.id != @image.user_id
      redirect_to @image, alert: "Can't edit images that aren't your own."
    end
  end

  # POST /images
  # POST /images.json
  def create
    if (image_params[:file].nil? && image_params[:url].nil?)
      return redirect_to root_path, notice: 'No file or URL to upload.'
    elsif !image_params[:url].nil?
      create_from_url
    else
      create_from_file
    end

    respond_to do |format|
      unless @image.new_record?
        flash[:success] = 'Image(s) uploaded successfully.'
        format.html { redirect_to @image }
        format.json { render action: 'show', status: :created, location: @image }
      else
        flash[:error] = 'Upload failed.'
        format.html { redirect_to '/' }
        format.json { render json: @image.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /images/editsubmit
  def edit_mode_submit
    if params[:delete]
      self.destroy
    else
      new_album
    end
  end

  # PATCH/PUT /images/1
  # PATCH/PUT /images/1.json
  def update
    respond_to do |format|
      if current_user.id != @image.user_id
        error_msg = "Can't edit images that aren't your own."
        format.html { redirect_to @image, notice: error_msg }
        format.json { render :json => { :errors => error_msg } }
      end

      if @image.update(image_params)
        format.html { redirect_to @image, notice: 'Image successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @image.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /images/1
  # DELETE /images/1.json
  def destroy
    if params[:key]
      image_ids = [ Image.find_by_key(params[:key]).id ]
    else
      image_ids = params[:selected]
    end

    respond_to do |format|
      if Image.delete_by_ids(current_user, image_ids)
        format.html { redirect_to user_path(current_user), notice: 'Image(s) deleted.' }
        format.json { head :no_content }
      else
        format.html { redirect_to user_path(current_user), notice: 'Error deleting image(s).'}
        format.json { render json: { errors: 'Error deleting image(s).' } }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_image
      @image = Image.find_by(key: params[:key])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def image_params
      params[:image].permit(:file, { file: [] }, :description, :url, :public)
    end

    def create_from_file
      image_params[:file].each do |file|
        image = { file: file }
        @image = current_user.images.new(image)
        break unless @image.save
      end
    end

    def create_from_url
      @image = current_user.images.new
      @image.file_remote_url = image_params[:url]
      @image.save
    end
end
