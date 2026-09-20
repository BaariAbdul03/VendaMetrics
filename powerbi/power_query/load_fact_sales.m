// ============================================================
// load_fact_sales.m — Power Query M Transformation for fact_sales View
// Source: MySQL olist_ecommerce.fact_sales
// Granularity: 1 row per delivered order item (110,197 rows)
// Pre-aggregates review scores to prevent fan-out multiplication
// ============================================================

let
    Source = MySQL.Database("localhost:3306", "olist_ecommerce", [ReturnSingleDatabase=true]),
    fact_table = Source{[Schema="olist_ecommerce", Item="fact_sales"]}[Data],
    
    TypedColumns = Table.TransformColumnTypes(fact_table, {
        {"order_id", type text},
        {"order_item_id", Int64.Type},
        {"product_id", type text},
        {"seller_id", type text},
        {"customer_id", type text},
        {"customer_unique_id", type text},
        {"order_status", type text},
        {"order_purchase_timestamp", type datetime},
        {"order_date", type date},
        {"order_approved_at", type datetime},
        {"order_delivered_carrier_date", type datetime},
        {"order_delivered_customer_date", type datetime},
        {"order_estimated_delivery_date", type datetime},
        {"price", Currency.Type},
        {"freight_value", Currency.Type},
        {"revenue", Currency.Type},
        {"delay_days", Int64.Type},
        {"is_late", Int64.Type},
        {"review_score", type number}
    })
in
    TypedColumns

