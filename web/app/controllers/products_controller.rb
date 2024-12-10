require 'shopify_api'
class ProductsController < AuthenticatedController
  def index
    products = ShopifyAPI::Product.all
    render json: products
  end

  def create
    store_1= Rails.application.credentials.store_1_access_token
    store_2= Rails.application.credentials.store_2_access_token  # mg-test-store-1 access token
      # mg-test-store-2 access token

    stores = [
      { domain: 'mg-test-store-1.myshopify.com', access_token: store_1 },
      { domain: 'mg-test-store-2.myshopify.com', access_token: store_2}
    ]

    errors = []
    threads = []

    stores.each do |store|
      threads << Thread.new do
        begin
          create_product_in_store(store[:domain], store[:access_token])
        rescue StandardError => e
          logger.error("Failed to create products in #{store[:domain]}: #{e.message}")
          errors << { store: store[:domain], error: e.message }
        end
      end
    end

    threads.each(&:join)

    if errors.empty?
      render(json: { success: true, error: nil })
    else
      render(json: { success: false, errors: errors }, status: :internal_server_error)
    end
  rescue StandardError => e
    logger.error("Unexpected error: #{e.message}")
    render(json: { success: false, error: e.message }, status: :internal_server_error)
  end

  def available_stores
    all_stores = Shop.all 
    render json: { stores: all_stores.map { |store| { id: store.id, name: store.shopify_domain } } }
  end

  def select_target_store
    target_store_id = params[:target_store]
    if target_store_id.present?
      session[:target_store_id] = target_store_id
      render json: { success: true, target_store: target_store_id }, status: :ok
    else
      render json: { success: false, error: 'No store selected' }, status: :unprocessable_entity
    end
  end

  def current_target_store
    target_store = session[:target_store_id]
    render json: { target_store: target_store }
  end

  def transfer_products
    target_store_id = params[:target_store_id]
    product_ids = params[:product_ids]

    if target_store_id.blank? || product_ids.blank?
      render json: { success: false, error: "Target store and product IDs are required" }, status: :unprocessable_entity
      return
    end
   
    target_store = Shop.find_by(id: target_store_id)
    current_store = Shop.where.not(id: target_store.id).order(:id).first
    ProductTransferJob.perform_later(target_store_id, product_ids, current_store.id)
    render json: { success: true, message: "Products are being transferred in the background." }
  end

  private

  def create_product_in_store(domain, access_token)
    uri = URI("https://#{domain}/admin/api/2023-10/products.json")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path, { 'Content-Type': 'application/json', 'X-Shopify-Access-Token': access_token })
    request.body = {
      product: {
        title: "New Product - #{Time.now.to_i}",
        body_html: "<strong>Good product!</strong>",
        vendor: "Test Vendor",
        product_type: "Test Type",
        variants: [
          { option1: "Default", price: "9.99", sku: "123" }
        ]
      }
    }.to_json

    response = http.request(request)
    unless response.is_a?(Net::HTTPSuccess)
      raise "HTTP Error: #{response.code} - #{response.message} - #{response.body}"
    end
  end

end