

class ProductsController < AuthenticatedController

  def index
    products = ShopifyAPI::Product.all
    render json: products
  end

  # def create
  #   ProductCreator.call(count: 5, session: current_shopify_session, id_token: shopify_id_token)
  #   render(json: { success: true, error: nil })
  # rescue StandardError => e
  #   logger.error("Failed to create products: #{e.message}")
  #   render(json: { success: false, error: e.message }, status: e.try(:code) || :internal_server_error)
  # end

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