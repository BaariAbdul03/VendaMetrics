// ============================================================
// clean_order_items.m — Power Query M Transformation for Order Items
// Source: MySQL olist_ecommerce.order_items
// ============================================================

let
    Source = MySQL.Database("localhost:3306", "olist_ecommerce", [ReturnSingleDatabase=true]),
    order_items_table = Source{[Schema="olist_ecommerce", Item="order_items"]}[Data],
    
    TypedColumns = Table.TransformColumnTypes(order_items_table, {
        {"order_id", type text},
        {"order_item_id", Int64.Type},
        {"product_id", type text},
        {"seller_id", type text},
        {"shipping_limit_date", type datetime},
        {"price", Currency.Type},
        {"freight_value", Currency.Type}
    }),
    
    // Add item revenue
    AddRevenue = Table.AddColumn(TypedColumns, "item_revenue", each [price] + [freight_value], Currency.Type)
in
    AddRevenue

