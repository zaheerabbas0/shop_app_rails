class ProductTransferJob < ApplicationJob
  queue_as :default
  def perform(target_store_id, product_ids, current_store_id)
    target_store = Shop.find_by(id: target_store_id)
    current_store = Shop.find_by(id: current_store_id)

    unless target_store && current_store
      Rails.logger.error "Invalid stores: target_store=#{target_store_id}, current_store=#{current_store_id}"
      return
    end

    ShopifyAPI::Context.activate_session(
      ShopifyAPI::Auth::Session.new(
        shop: current_store.shopify_domain,
        access_token: current_store.shopify_token
      )
    )

    products_to_transfer = product_ids.map do |id|
      begin
        product = ShopifyAPI::Product.find(id: id)
        product
      rescue => e
        Rails.logger.error "Error fetching product ID #{id}: #{e.message}"
        nil
      end
    end.compact

    ShopifyAPI::Context.activate_session(
      ShopifyAPI::Auth::Session.new(
        shop: target_store.shopify_domain,
        access_token: target_store.shopify_token
      )
    )

    products_to_transfer.each do |product|
      begin
        new_product = ShopifyAPI::Product.new
        new_product.title = product.title
        new_product.body_html = product.body_html
        new_product.vendor = product.vendor
        new_product.product_type = product.product_type
        if product.variants.present?
          new_product.variants = product.variants.compact.map do |variant|
            variant.attributes.except("id") if variant.attributes.present?
          end.compact
        end

        if product.images.present?
          new_product.images = product.images.compact.map do |image|
            { src: image.src } if image.src.present?
          end.compact
        end
        new_product.save!
      rescue => e
        Rails.logger.error "Error transferring product #{product.id}: #{e.message}"
      end
    end
  end
end
