// ============================================================
// clean_orders.m — Power Query M Transformation Script for Orders
// Source: MySQL olist_ecommerce.orders (or CSV fallback)
// ============================================================

let
    // Connect to MySQL (Change server/db if needed)
    Source = MySQL.Database("localhost:3306", "olist_ecommerce", [ReturnSingleDatabase=true]),
    orders_table = Source{[Schema="olist_ecommerce", Item="orders"]}[Data],
    
    // Type casting
    TypedColumns = Table.TransformColumnTypes(orders_table, {
        {"order_id", type text},
        {"customer_id", type text},
        {"order_status", type text},
        {"order_purchase_timestamp", type datetime},
        {"order_approved_at", type datetime},
        {"order_delivered_carrier_date", type datetime},
        {"order_delivered_customer_date", type datetime},
        {"order_estimated_delivery_date", type datetime}
    }),
    
    // Split order_purchase_timestamp into date and time
    AddPurchaseDate = Table.AddColumn(TypedColumns, "order_purchase_date", each DateTime.Date([order_purchase_timestamp]), type date),
    AddPurchaseTime = Table.AddColumn(AddPurchaseDate, "order_purchase_time", each DateTime.Time([order_purchase_timestamp]), type time),
    
    // Delivery calculations
    AddDeliveryDays = Table.AddColumn(AddPurchaseTime, "delivery_days", each 
        if [order_delivered_customer_date] <> null and [order_purchase_timestamp] <> null 
        then Duration.Days([order_delivered_customer_date] - [order_purchase_timestamp]) 
        else null, Int64.Type),
        
    AddDelayDays = Table.AddColumn(AddDeliveryDays, "delay_days", each 
        if [order_delivered_customer_date] <> null and [order_estimated_delivery_date] <> null 
        then Duration.Days([order_delivered_customer_date] - [order_estimated_delivery_date]) 
        else null, Int64.Type),
        
    AddIsLate = Table.AddColumn(AddDelayDays, "is_late", each 
        if [order_delivered_customer_date] <> null and [order_estimated_delivery_date] <> null 
        then (if [order_delivered_customer_date] > [order_estimated_delivery_date] then 1 else 0) 
        else 0, Int64.Type),
        
    AddDelayBucket = Table.AddColumn(AddIsLate, "delay_bucket", each 
        if [delay_days] = null then "Undelivered"
        else if [delay_days] <= -7 then "Early (>7d)"
        else if [delay_days] <= 0 then "On-time (0-7d early)"
        else if [delay_days] <= 3 then "Slightly Late (1-3d)"
        else if [delay_days] <= 7 then "Late (4-7d)"
        else "Very Late (>7d)", type text)
in
    AddDelayBucket

