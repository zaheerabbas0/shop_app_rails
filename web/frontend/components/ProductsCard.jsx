import { useState } from "react";
import { Card, TextContainer, Text, Layout, Thumbnail } from "@shopify/polaris";
import { useQuery } from "react-query";

export function ProductsCard() {
  const [isPopulating, setIsPopulating] = useState(false);
  const [products, setProducts] = useState([]);

  const {
    data,
    refetch: refetchProduct,
    isLoading: isLoading,
  } = useQuery({
    queryKey: ["productList"],
    queryFn: async () => {
      const response = await fetch("/api/products");
      const result = await response.json();
      setProducts(result); // Save products to state
      return result;
    },
    refetchOnWindowFocus: false,
  });

  const handlePopulate = async () => {
    setIsPopulating(true);
    const response = await fetch("/api/products", { method: "POST" });

    if (response.ok) {
      await refetchProduct();
    }

    setIsPopulating(false);
  };

  return (
    <Card
      title="Products"
      sectioned
      primaryFooterAction={{
        content: `Populate Products`,
        onAction: handlePopulate,
        loading: isPopulating,
      }}
    >
      <TextContainer spacing="loose">
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(250px, 1fr))",
            gap: "16px",
            marginTop: "20px",
          }}
        >
          {products.map((product) => (
            <Card key={product.id} sectioned>
              <div style={{ textAlign: "center" }}>
                {/* Display Product Image */}
                {product.image ? (<Thumbnail source={product.image.src} alt={product.title} />) : (
                  <Thumbnail
                    source="https://via.placeholder.com/150"
                    alt="Placeholder image"
                  />
                )}
              </div>
              <Text as="h5" variant="headingMd">
                {product.title}
              </Text>
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