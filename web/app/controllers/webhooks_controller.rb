class WebhooksController < ApplicationController

  def products_update
    payload = params.permit!.to_h
    source_product_id = payload['id']
    source_product_title = payload['title']
    source_sku = payload.dig('variants', 0, 'sku') 
    source_price = payload.dig('variants', 0, 'price')
    payload = JSON.parse(request.body.read)
    sku = payload['variants'].first['sku']
    target_store = Shop.find_by(shopify_token: Rails.application.credentials.store_1_access_token)
    ShopifyAPI::Context.activate_session(
      ShopifyAPI::Auth::Session.new(
        shop: target_store.shopify_domain,
        access_token: target_store.shopify_token
      )
    )
    begin
      product = ShopifyAPI::Product.find(id: source_product_id, session: ShopifyAPI::Context.active_session)
      if product
        begin
          # setting up store 2.
          target_store = Shop.find_by(shopify_token: Rails.application.credentials.store_2_access_token)
          ShopifyAPI::Context.activate_session(
            ShopifyAPI::Auth::Session.new(
              shop: target_store.shopify_domain,
              access_token: target_store.shopify_token
            )
          )
          product = ShopifyAPI::Product.all.find(variants: {sku: source_sku}).first
        rescue => e
          Rails.logger.error "not able to find product for #{target_store.inspect}: #{e.message}"
          return render json: { success: false, error: e.message }, status: :internal_server_error
        end
      end
    rescue => e
      product = ShopifyAPI::Product.all.find(variants: {sku: source_sku}).first
    end


    if product
        
        product.title = payload['title']
        product.body_html = payload['body_html']
        product.vendor = payload['vendor']
        product.product_type = payload['product_type']

        if payload['variants'].present?
          product.variants.each_with_index do |variant, index|
            variant_data = payload['variants'][index]
            variant.price = variant_data['price'] if variant_data['price'].present?
            variant.sku = variant_data['sku'] if variant_data['sku'].present?
            # Add other fields as necessary
          end
        end

        if payload['images'].present?
          product.images = payload['images'].map do |image|
            { src: image['src'] } if image['src'].present?
          end.compact
        end

        product.save!
        puts "Product updated successfully"
      else
        puts "Product not found"
      end
    render json: { success: true }, status: :ok
  rescue => e
    Rails.logger.error "Error syncing product: #{e.message}"
    render json: { success: false, error: e.message }, status: :internal_server_error
  end
end
