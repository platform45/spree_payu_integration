class PayuSoap
  # extend Savon::Model

  #   # client wsdl: "https://secure.payu.co.za/service/PayUAPI?wsdl"  #production
  include Rails.application.routes.url_helpers
  require 'savon'
  # require 'pp'
  # require 'rubygems'
  # require 'pry'

  def initialize(order, ip, order_url, notify_url, continue_url, cancel_url)
    @order = order
    @user = @order.user
    @ip = ip
    @order_url = order_url
    @notify_url = notify_url
    @continue_url = continue_url
    @cancel_url = cancel_url
    @desc = ""

    @products = order.line_items.map do |li|
      # {
      #   name: li.product.name,
      #   unit_price: (li.price * 100).to_i,
      #   quantity: li.quantity
      # }
      @desc += li.product.name + " "
    end

    @client = Savon.client({
      :wsdl => "https://staging.payu.co.za/service/PayUAPI?wsdl",
      :pretty_print_xml => true,
      :log_level => :debug,
      :wsse_auth => ["100032", "PypWWegU"],
    })

  end

  def set_transaction
    reponse = @client.call(:set_transaction, message: set_transaction_request )
  rescue Savon::SOAPFault => error
      pp error.to_hash
  end

  def get_transaction
     reponse = @client.call(:get_transaction, message: get_transaction_request )
  rescue Savon::SOAPFault => error
      pp error.to_hash
  end

  private

  def set_transaction_request
    {
      "Api" => "ONE_ZERO",
      "Safekey" => "{CE62CE80-0EFD-4035-87C1-8824C5C46E7F}",
      "TransactionType" => "PAYMENT",
      "AdditionalInformation" => {
          "merchantReference" => @order.number,
          "notificationUrl" => @notify_url,
          "cancelUrl" => @cancel_url,
          # "returnUrl" => @continue_url,
          "returnUrl" => @cancel_url,
          "supportedPaymentMethods" => "CREDITCARD"
      },
      "Customer" => {
        "email" => @user.email,
        "firstName" => @user.name,
        "merchantUserId" => @user.id
      },
      "Basket" => {
        "amountInCents" => (@order.total * 100).to_i,
        "currencyCode" => "ZAR",
        "description" => @desc
      }
    }
  end

  def get_transaction_request
    {
      "Api" => "ONE_ZERO",
      "Safekey" => "{CE62CE80-0EFD-4035-87C1-8824C5C46E7F}",
      "AdditionalInformation" => {
          "merchantReference" => @order.number
      }
    }
  end

end
