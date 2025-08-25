require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should redirect to sign in when not authenticated" do
    get home_index_url
    assert_redirected_to new_session_path
  end

  test "should get index when authenticated" do
    sign_in_as(users(:manager))
    get home_index_url
    assert_response :success
  end

  test "should get root when authenticated" do
    sign_in_as(users(:worker))
    get root_url
    assert_response :success
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password123" }
  end
end
