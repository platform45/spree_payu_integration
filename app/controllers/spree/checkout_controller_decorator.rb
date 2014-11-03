Spree::CheckoutController.class_eval do

  #before_filter :pay_with_payu, only: :update
  before_filter :check_reference_from_payu, only: :update

  private

  def check_reference_from_payu
    puts "************************"
    puts "payment method payu #{payment_method_is_payu?}"
    puts "************************"
    if params.has_key?('PayUReference') && payment_method_is_payu?
      payu_get_transaction
    elsif payment_method_is_payu?
      payu_set_transaction
    end
  rescue StandardError => e
    payu_error(e)
  end

  def payu_set_transaction
    return unless params[:state] == 'payment'
    @payu_order = PayuSoap.new(@order, request.remote_ip, order_url(@order), payu_notify_url,
                                order_url(@order), request.url)
    response = @payu_order.set_transaction.body

    set_payu_reference(response[:set_transaction_response][:return][:pay_u_reference])
    # payu_url = 'https://secure.payu.co.za/rpp.do?PayUReference=' + payu_reference
    payu_url = 'https://staging.payu.co.za/rpp.do?PayUReference=' + payu_reference

    redirect_to payu_url
  end

  def payu_get_transaction
    @payu_order = PayuSoap.new(@order, request.remote_ip, order_url(@order), payu_notify_url,
                                order_url(@order), request.url)

    response = @payu_order.get_transaction.body[:get_transaction_response][:return]
    puts "************************"
    puts response
    puts "************************"

    if response[:successful] && response[:transaction_state] == 'SUCCESSFUL'
      flash.notice = response[:display_message]

        puts "************************"
        puts "success"
        puts "************************"
      payment_success(payment_method)
      redirect_to order_url(@order)
    else
      flash.notice = response[:display_message]
      puts "************************"
      puts 'fail'
      puts "************************"

      payu_error
    end
  end

  def payment_method_is_payu?
    pm_id = params[:order][:payments_attributes].first[:payment_method_id]
    payment_method = Spree::PaymentMethod.find(pm_id)
    return (payment_method && payment_method.kind_of?(Spree::PaymentMethod::Payu))
  end

  def set_payu_reference(reference)
    @reference = reference
  end

  def payu_reference
    @reference
  end

  def payment_success(payment_method)
    payment = @order.payments.build(
      payment_method_id: payment_method.id,
      amount: @order.total,
      state: 'checkout'
    )

    unless payment.save
      flash[:error] = payment.errors.full_messages.join("\n")
      redirect_to checkout_state_path(@order.state) and return
    end

    unless @order.next
      flash[:error] = @order.errors.full_messages.join("\n")
      redirect_to checkout_state_path(@order.state) and return
    end

    payment.pend!
  end

  def payu_error(e = nil)
    @order.errors[:base] << "PayU error #{e.try(:message)}"
    render :edit
  end

end
