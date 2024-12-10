# frozen_string_literal: true
require 'shopify_api'
class ApplicationJob < ActiveJob::Base
   ShopifyAPI::Context.setup(
      api_key: Rails.application.credentials.SHOPIFY_API_KEY,
      api_secret_key: Rails.application.credentials.SHOPIFY_API_SECRET,
      api_version: ShopifyApp.configuration.api_version,
      host_name: URI(ENV.fetch("HOST", "")).host || "",
      scope: ShopifyApp.configuration.scope,
      is_private: !ENV.fetch("SHOPIFY_APP_PRIVATE_SHOP", "").empty?,
      is_embedded: ShopifyApp.configuration.embedded_app,
      logger: Rails.logger,
      log_level: :info,
      private_shop: ENV.fetch("SHOPIFY_APP_PRIVATE_SHOP", nil),
      user_agent_prefix: "ShopifyApp/#{ShopifyApp::VERSION}",
      old_api_secret_key: ShopifyApp.configuration.old_secret,
    )
end
