# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end


  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
  def facebook_callback
    # Lấy mã `code` từ URL
    code = params[:code]

    # Gửi yêu cầu tới Facebook để đổi mã `code` thành access token
    access_token_response = HTTParty.get("https://graph.facebook.com/v11.0/oauth/access_token", query: {
      client_id: '1551842505695918',
      redirect_uri: 'http://localhost:3000/auth/facebook/callback',
      client_secret: '3b4f360c3fd532ddabeac5b218ba417d',
      code: code
    })

    # Lấy access token từ phản hồi
    access_token = access_token_response.parsed_response["access_token"]

    # Bây giờ bạn có thể dùng `access_token` để truy vấn dữ liệu từ Facebook API
  end
  
end
