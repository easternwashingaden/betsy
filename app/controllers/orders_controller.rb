class OrdersController < ApplicationController
  skip_before_action :require_login
  before_action :find_cart, only: [ :clear_cart, :submit_order, :checkout ]
  before_action :find_order, only: [ :show_complete, :cancel]


  def cart
    if session[:cart_id]
      @order = Order.find_by(id: session[:cart_id])
    else
      @order = Order.new
      if @order.save
        session[:cart_id] = @order.id
      end
    end
  end

  def clear_cart
    @order.clear_cart
    flash[:success] = "Cart cleared."
    redirect_to cart_path
  end

  def checkout; end

  def submit_order
    @order.submit_order
    if @order.update(order_params)
      session[:cart_id] = nil
      flash[:success] = "Your order has been submitted!"
      redirect_to complete_order_path(@order)
      return
    else
      flash.now[:error] = "Woops, #{@order.errors.messages}"
      render :checkout
      return
    end
  end

  def show_complete; end

  def cancel
    @order.cancel
    flash[:success] = "Your order was cancelled."
    redirect_to root_path
    return
  end

  private
  def find_cart
    @order = Order.find_by(id: session[:cart_id])
    if @order.nil?
      head :not_found
      return
    end
  end

  def find_order
    @order = Order.find_by(id: params[:id])    
    if @order.nil?
      head :not_found
      return
    end
  end

  def order_params
    return params.require(:order).permit(:name, :email, :address, :cc_last_four,:cc_exp_year, :cc_exp_month, :cc_cvv)
  end

end
