import { useState, useEffect } from "react";
import { Card, TextContainer, Text, Layout, Thumbnail, Select, Button } from "@shopify/polaris";

export function ProductsCard() {
  const [isPopulating, setIsPopulating] = useState(false);
  const [products, setProducts] = useState([]);
  const [stores, setStores] = useState([]);
  const [selectedStore, setSelectedStore] = useState("");
  const [selectedProducts, setSelectedProducts] = useState([]);

  const fetchProducts = async () => {
    const response = await fetch("/api/products");
    const data = await response.json();
    setProducts(data);
  };

  const fetchStores = async () => {
    const response = await fetch("/api/products/available_stores");
    const data = await response.json();
    setStores(data.stores);

    // Fetch the current target store scoped to this Shopify store
    const targetStoreResponse = await fetch("/api/products/current_target_store");
    const targetData = await targetStoreResponse.json();
    setSelectedStore(targetData.target_store || ""); // Set to empty if no store selected
  };

  useEffect(() => {
    fetchProducts();
    fetchStores();
  }, []);

  const handleStoreChange = async (value) => {
    setSelectedStore(value);

    try {
      const response = await fetch("/api/products/select_target_store", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Shopify-Shop-Domain": "mg-test-store-1.myshopify.com", 
        },
        body: JSON.stringify({ target_store: value }),
      });

      if (!response.ok) {
        throw new Error("Failed to update target store on backend.");
      }
    } catch (error) {
      console.error("Error updating target store:", error);
      alert("Unable to update the target store. Please try again.");
    }
  };

  const handleProductSelection = (productId) => {
    setSelectedProducts((prevSelected) =>
      prevSelected.includes(productId)
        ? prevSelected.filter((id) => id !== productId)
        : [...prevSelected, productId]
    );
  };

  const handleTransferProducts = async () => {
    if (!selectedStore) {
      alert("Please select a target store.");
      return;
    }

    const response = await fetch("/api/products/transfer_products", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        target_store_id: selectedStore,
        product_ids: selectedProducts,
      }),
    });
  };

  const handlePopulate = async () => {
    setIsPopulating(true);
    const response = await fetch("/api/products", { method: "POST" });

    if (response.ok) {
      await fetchProducts();
    }

    setIsPopulating(false);
  };

  return (
    <Card
      title="Products"
      sectioned
      primaryFooterAction={{
        content: "Populate Products",
        onAction: handlePopulate,
        loading: isPopulating,
      }}
    >
      <TextContainer spacing="loose">
        {/* Store Selector */}
         <Select
          label="Select Target Store"
          options={[
            { label: "Select Target Store", value: "" }, // Placeholder
            ...stores.map((store) => ({
              label: store.name,
              value: store.id.toString(),
            })),
          ]}
          value={selectedStore}
          onChange={handleStoreChange}
        />
        <div style={{ marginTop: "10px" }}>
          <Button
            onClick={handleTransferProducts}
            disabled={!selectedStore || selectedProducts.length === 0}
            primary
          >
            Transfer Selected Products
          </Button>
        </div>

        {/* Product List */}
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(250px, 1fr))",
            gap: "16px",
            marginTop: "20px",
          }}
        >
          {products.map((product) => (
            <Card
              key={product.id}
              sectioned
              title={product.title}
              actions={[
                {
                  content: selectedProducts.includes(product.id)
                    ? "Deselect"
                    : "Select",
                  onAction: () => handleProductSelection(product.id),
                },
              ]}
            >
              <div style={{ textAlign: "center" }}>
                {product.image ? (
                  <Thumbnail source={product.image.src} alt={product.title} />
                ) : (
                  <Thumbnail
                    source="https://via.placeholder.com/150"
                    alt="Placeholder image"
                  />
                )}
              </div>
              <Text variant="bodyMd" as="p" fontWeight="semibold">
                Type: {product.product_type || "Unknown"}
              </Text>
              <Text variant="bodyMd" as="p">
                Vendor: {product.vendor}
              </Text>
            </Card>
          ))}
        </div>
      </TextContainer>
    </Card>
  );
}
