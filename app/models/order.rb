class Order < ApplicationRecord
  VALID_STATUSES = ["pending", "paid", "cancelled"] 
  has_many :order_items
  has_many :products, through: :order_items

  validates :status, presence: true, inclusion: { in: VALID_STATUSES, message: "Status invalid."} 
  def order_submitted?
    status == "paid" || status == "shipped" || status == "cancelled" 
  end
  with_options if: :order_submitted? do |submitted|
    submitted.validates :name, presence: true
    submitted.validates :email, presence: true, 
      format: { with: /[a-z0-9\+\-_\.]+@[a-z\d\-]+\.[a-z]+\z/, message: "email is not valid" }
    submitted.validates :address, presence: true
    submitted.validates :cc_last_four, presence: true, 
      format: { with: /\d{4}/, message: "cc_last_four is not valid" }
    submitted.validates :cc_exp_month, presence: true, 
      format: { with: /\d{2}/, message: "month exp must be in MM format" }
    submitted.validates :cc_exp_year, presence: true, 
      format: { with: /\d{4}/, message: "year exp must be in YYYY format" }
    submitted.validates :cc_cvv, presence: true, 
      format: { with: /\d{3,4}/, message: "invalid cvv" }
    submitted.validates_with Datevalidator
  end


  def cancel
    self.status = "cancelled"
    self.save
    return change_items(:restock)
  end

  def clear_cart
    self.order_items.destroy_all
  end 

  def total_price
    total = 0.0
    self.order_items.each do |order_item|
      total += order_item.product.price * order_item.quantity
    end
    return total
  end

  def find_order_item(product)
    self.order_items.each do |order_item|
      if order_item.product == product
        return order_item
      end
    end
    return nil
  end

  def submit_order
    if self.status != "pending"
      return false
    end
    self.status = "paid"
    return change_items(:destock)
  end

  def cc_num_is_correct(cc_num)
    if /\d{16}/.match?(cc_num)
      return true
    else
      errors.add(:cc_validation, "Credit card number must be 16 digits")
      return false
    end
  end

  private

  def change_items(change)
    all_changed = true
    self.order_items.each do |item|
      if !item.method(change).call
        errors.add("order_item#{item.id}".to_sym, item.errors[:status])
        all_changed = false
      end
    end
    return all_changed
  end

  
end
