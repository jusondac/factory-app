require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @manager = users(:manager)
    @worker = users(:worker)
    @product = products(:chocolate_cake)
    sign_in_as(@manager)
  end

  test "should get index" do
    get products_url
    assert_response :success
    assert_select "h1", "Products"
  end

  test "should get show" do
    get product_url(@product)
    assert_response :success
  end

  test "should get new as manager" do
    get new_product_url
    assert_response :success
    assert_select "h1", "New Product"
  end

  test "should not get new as worker" do
    sign_in_as(@worker)
    get new_product_url
    assert_redirected_to root_path
    assert_equal "Only managers and heads can manage products.", flash[:alert]
  end

  test "should create product as manager" do
    assert_difference "Product.count", 1 do
      post products_url, params: {
        product: { name: "New Test Product" }
      }
    end

    assert_redirected_to product_url(Product.last)
    assert_equal "Product was successfully created.", flash[:notice]
  end

  test "should not create product as worker" do
    sign_in_as(@worker)
    assert_no_difference "Product.count" do
      post products_url, params: {
        product: { name: "New Test Product" }
      }
    end

    assert_redirected_to root_path
  end

  test "should get edit as product owner" do
    get edit_product_url(@product)
    assert_response :success
    assert_select "h1", "Edit Product"
  end

  test "should update product as owner" do
    patch product_url(@product), params: {
      product: { name: "Updated Product Name" }
    }

    assert_redirected_to product_url(@product)
    assert_equal "Product was successfully updated.", flash[:notice]
    @product.reload
    assert_equal "Updated Product Name", @product.name
  end

  test "should destroy product as owner" do
    assert_difference "Product.count", -1 do
      delete product_url(@product)
    end

    assert_redirected_to products_url
    assert_equal "Product was successfully deleted.", flash[:notice]
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password123" }
  end
end
