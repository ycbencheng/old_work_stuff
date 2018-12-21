# frozen_string_literal: true

class ImportWorker
  include Sidekiq::Worker

  def perform(store_id, conditions = {})
    store = Store.find(store_id)
    conditions[:store_id] = store_id
    order_header = Order::Header.joins(:customer, :product)
                                .includes({ customer: :addresses }, :product)
                                .where(conditions)
                                .map do |dh|
      address = dh.customer.addresses.first
      {
        first_name: dh.customer.first_name,
        last_name: dh.customer.last_name,
        street: address&.street,
        city: address&.city,
        state: address&.state,
        zip: address&.zip,
        year: dh.product.year,
        make: dh.product.make,
        model: dh.product.model,
      }
    end
    LexisNexis::Service.new(store).create_send_list_items(order_header)
  end
end
