require "test_helper"

describe ProductsController do
  before do
    @product = Product.new(
      name: "Xxxx", 
      price: 20.00,
      stock: 20,
      active: false,
      description: "XXX XXX XXXX XXX XXXXXXXXXX XXXXXXXX XXXXXXXX XXXXXXX XXXXX XXXX XXXXX",
      photo: "https://i.imgur.com/WSHmeuf.jpg",
      merchant: merchants(:merchantaaa)
    )

    @product_one = products(:product1)

    @merchant = merchants(:merchantaaa)
    perform_login(@merchant)

    @edited_product_hash = {
      product: {
        name: "XXXX", 
        price: 20.00,
        stock: 20,
        active: false,
        description: "Description for the new movie",
        photo: "https://i.imgur.com/WSHmeuf.jpg",
        merchant_id: @merchant.id,
      } 
    }
  end

  describe "index" do
    it "responds with success when there are many products saved" do
      @product.save
      get products_path
      must_respond_with :success
    end

    it "responds with success when there are no product saved" do
      get products_path
      must_respond_with :success
    end
  end

  describe "new" do
    it "responds with success" do
      get new_product_path
      must_respond_with :success
    end
  end

  describe "show" do
    it "responds with success when showing an existing valid product" do
      @product.save
      get product_path(@product.id)
      must_respond_with :success
    end

    it "responds with 404 with an invalid product id" do
      get product_path(-1)
      must_redirect_to products_path
    end
  end

  describe "create" do
    before do
      @product_hash = {
        product: {
          name: "Xxxx", 
          price: 20.00,
          stock: 20,
          active: true,
          description: "Description for the new movie",
          photo: "https://i.imgur.com/WSHmeuf.jpg",
          merchant_id: @merchant.id,
      } 
    }
    end

    it "can create a new product with valid information accurately if the user is logged in, and redirect" do
      expect {
        post products_path, params: @product_hash
      }.must_differ "Product.count", 1
      
      expect(Product.last.name).must_equal @product_hash[:product][:name]
      expect(Product.last.price).must_equal @product_hash[:product][:price]
      expect(Product.last.stock).must_equal @product_hash[:product][:stock]
      expect(Product.last.active).must_equal @product_hash[:product][:active]
      expect(Product.last.description).must_equal @product_hash[:product][:description]
      expect(Product.last.merchant_id).must_equal @product_hash[:product][:merchant_id]

      expect(flash[:success]).must_equal "Successfully created #{@product.name}"
      must_redirect_to account_path(@merchant)
    end

    it "does not create a product if name is not present, and responds with bad_request" do
      @product_hash[:product][:name] = nil
  
      expect {
        post products_path, params: @product_hash
      }.wont_change "Product.count"
      assert_response :bad_request
    end

    it "does not create a product if price is not present, and responds with bad_request" do
      @product_hash[:product][:price] = nil
      expect {
        post products_path, params: @product_hash
      }.wont_change "Product.count"
      assert_response :bad_request
    end

    it "does not create a product if stock is not present, and responds with bad_request" do
      @product_hash[:product][:stock] = nil
      expect {
        post products_path, params: @product_hash
      }.wont_change "Product.count"
      assert_response :bad_request
    end

    it "does not create a product if description is not present, and responds with bad_request" do
      @product_hash[:product][:description] = nil
      expect {
        post products_path, params: @product_hash
      }.wont_change "Product.count"
      expect(flash.now[:error]).must_equal "A problem occurred: Could not create product"
      assert_response :bad_request
    end

    it "does not create a product if merchant is not logedin" do
      put logout_path, params: {}
      expect {
        post products_path, params: @product_hash
      }.wont_change "Product.count"
      must_redirect_to root_path
    end
    
  end
  
  describe "edit" do
    it "responds with success when getting the edit page for an existing, valid product" do
      get edit_product_path(@product_one.id)
      must_respond_with :success
    end

    it "responds with redirect when getting the edit page for a non-existing product" do
      get edit_product_path(-1)
      must_redirect_to products_path
    end
  end

  describe "update" do
    it "can update an existing product with valid information accurately, and redirect" do
      id = @product_one.id

      expect{
        patch product_path(id), params: @edited_product_hash
      }.wont_change "Product.count"

      @product_one.reload
      expect(@product_one.name).must_equal @edited_product_hash[:product][:name]
      expect(@product_one.price).must_equal @edited_product_hash[:product][:price]
      expect(@product_one.stock).must_equal @edited_product_hash[:product][:stock]
      expect(@product_one.active).must_equal @edited_product_hash[:product][:active]
      expect(@product_one.description).must_equal @edited_product_hash[:product][:description]
      expect(@product_one.merchant_id).must_equal @edited_product_hash[:product][:merchant_id]

      expect(flash[:success]).must_equal "Successfully updated #{@product_one.name.titleize}"
      must_redirect_to product_path(id)
    end

    it "does not update any product if given an invalid id, and responds with a 404" do
      expect{
        patch product_path(-1), params: @edited_product_hash
      }.wont_change "Product.count"
      expect(flash[:error]).must_equal "Product not found."
      must_redirect_to products_path
    end

    it "does not update a product if the form data violates Product validations, and responds with a 400 error" do
      @edited_product_hash[:product][:price] = nil

      expect{
        patch product_path(@product_one), params: @edited_product_hash
      }.wont_change "Product.count"
    
      expect(flash.now[:error]).must_include "price"
      expect(flash.now[:error]).must_include "can't be blank"
      assert_response :bad_request
    end
  end 

  describe "destroy" do
    before do
     # Prodcut4 links to order_item4(pending) and order_item5(shipped)
      @product4 = products(:product4) # we cannot delete it
     # Product 2 doesn't link to anything order_items - we can destroy it
      @product2 = products(:product2)
     # Product 6 links to to order_item7(shipped) - we can deleted this
      @product6 = products(:product6)
    end

    it "Can destroy product if the product is NOT associated to any order/order_item that is pending or paid status" do
      expect {
        delete product_path(@product6.id)
      }.must_differ "Product.count", -1
      expect(flash[:success]).must_equal "Successfully deleted the product"
      must_redirect_to account_path(@merchant)
    end

    it "Can destroy the product if the product is NOT associated to any order" do
      expect {
        delete product_path(@product2.id)
      }.must_differ "Product.count", -1
      expect(flash[:success]).must_equal "Successfully deleted the product"
      must_redirect_to account_path(@merchant)
    end

    it "Cannot destroy the product if the product is associated to order/order_item that is pending or paid status " do
    expect {
      delete product_path(@product4.id)
    }.wont_change "Product.count"
    expect(flash[:warning]).must_equal "Sorry, You cannot delete for this product."
    must_redirect_to account_path(@merchant)
    end

    it "Get 404 if the product is not a valid product" do
      expect {
        delete product_path(-1)
      }.wont_change "Product.count"
      expect(flash[:error]).must_equal "Product not found."
      must_redirect_to products_path
    end

    it "A merchant cannot destory other's merchants' products" do
      @merchant1 = merchants(:merchantbbb)
      perform_login(@merchant1)
      expect {
        delete product_path(@product2.id)
      }.wont_change "Product.count"
    end
  end

  describe "toggle_active" do
    it "Get 404 if the product is not a valid product" do
      expect {
        patch product_active_path(-1), params: @edited_product_hash
      }.wont_change "Product.count"
      expect(flash[:error]).must_equal "Product not found."
      must_redirect_to products_path
    end

    it "Can toggle product to be active or de-active (active product)" do
      expect {
        patch product_active_path(@product_one.id), params: @edited_product_hash
      }.wont_change "Product.count"
      @product_one.reload
      expect(@product_one.active).must_equal @edited_product_hash[:product][:active]
      must_redirect_to account_path(@merchant)
    end
    it "Can toggle product to be active or de-active (unactive)" do
    inactive = products(:product_inactive)
      expect {
        patch product_active_path(inactive.id)
      }.wont_change "Product.count"
      inactive.reload
      #expect(inactive.active).must_equal @edited_product_hash[:product][:active]
      must_redirect_to account_path(@merchant)
    end
  end
end

