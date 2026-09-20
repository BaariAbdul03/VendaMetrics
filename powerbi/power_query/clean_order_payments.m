// ============================================================
// clean_order_payments.m — Power Query M Transformation for Order Payments
// Source: MySQL olist_ecommerce.order_payments
// ============================================================

let
    Source = MySQL.Database("localhost:3306", "olist_ecommerce", [ReturnSingleDatabase=true]),
    payments_table = Source{[Schema="olist_ecommerce", Item="order_payments"]}[Data],
    
    TypedColumns = Table.TransformColumnTypes(payments_table, {
        {"order_id", type text},
        {"payment_sequential", Int64.Type},
        {"payment_type", type text},
        {"payment_installments", Int64.Type},
        {"payment_value", Currency.Type}
    }),
    
    // Normalize payment type names (replace underscore with space, capitalize)
    CleanPaymentType = Table.TransformColumns(TypedColumns, {
        {"payment_type", each Text.Proper(Text.Replace(_, "_", " ")), type text}
    })
in
    CleanPaymentType

