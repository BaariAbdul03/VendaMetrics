// ============================================================
// clean_order_reviews.m — Power Query M Transformation for Order Reviews
// Source: MySQL olist_ecommerce.order_reviews
// ============================================================

let
    Source = MySQL.Database("localhost:3306", "olist_ecommerce", [ReturnSingleDatabase=true]),
    reviews_table = Source{[Schema="olist_ecommerce", Item="order_reviews"]}[Data],
    
    TypedColumns = Table.TransformColumnTypes(reviews_table, {
        {"review_id", type text},
        {"order_id", type text},
        {"review_score", Int64.Type},
        {"review_creation_date", type datetime},
        {"review_answer_timestamp", type datetime}
    }),
    
    // Rating category: Positive (4-5), Neutral (3), Negative (1-2)
    AddSentiment = Table.AddColumn(TypedColumns, "review_sentiment", each 
        if [review_score] >= 4 then "Positive (4-5★)"
        else if [review_score] = 3 then "Neutral (3★)"
        else "Negative (1-2★)", type text)
in
    AddSentiment

