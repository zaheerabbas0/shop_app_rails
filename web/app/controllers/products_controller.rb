class ProductsController < AuthenticatedController

  def index
    products = ShopifyAPI::Product.all
    render json: products
  end

  def create
    ProductCreator.call(count: 5, session: current_shopify_session, id_token: shopify_id_token)
    render(json: { success: true, error: nil })
  rescue StandardError => e
    logger.error("Failed to create products: #{e.message}")
    render(json: { success: false, error: e.message }, status: e.try(:code) || :internal_server_error)
  end

end
