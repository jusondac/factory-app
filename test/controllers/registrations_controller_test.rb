require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_registration_url
    assert_response :success
    assert_select "h1", "Sign up"
  end

  test "should create user with valid attributes" do
    assert_difference "User.count", 1 do
      post registration_url, params: {
        user: {
          email_address: "test@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_redirected_to root_url
    assert_equal "Welcome! You have signed up successfully.", flash[:notice]

    # User should be automatically signed in
    user = User.find_by(email_address: "test@example.com")
    assert_not_nil user
    assert user.sessions.any?
  end

  test "should not create user with invalid attributes" do
    assert_no_difference "User.count" do
      post registration_url, params: {
        user: {
          email_address: "",
          password: "pass",
          password_confirmation: "different"
        }
      }
    end

    assert_response :unprocessable_content
    assert_select "h1", "Sign up"
  end

  test "should not create user with duplicate email" do
    User.create!(email_address: "test@example.com", password: "password123")

    assert_no_difference "User.count" do
      post registration_url, params: {
        user: {
          email_address: "test@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_response :unprocessable_content
  end
end
