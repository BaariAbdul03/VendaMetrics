// ============================================================
// clean_products.m — Power Query M Transformation Script for Products
// Source: MySQL olist_ecommerce.products + product_category_translation
// ============================================================

let
    Source = MySQL.Database("localhost:3306", "olist_ecommerce", [ReturnSingleDatabase=true]),
    products_table = Source{[Schema="olist_ecommerce", Item="products"]}[Data],
    translation_table = Source{[Schema="olist_ecommerce", Item="product_category_translation"]}[Data],
    
    // Cast base product columns
    TypedProducts = Table.TransformColumnTypes(products_table, {
        {"product_id", type text},
        {"product_category_name", type text},
        {"product_name_lenght", Int64.Type},
        {"product_description_lenght", Int64.Type},
        {"product_photos_qty", Int64.Type},
        {"product_weight_g", type number},
        {"product_length_cm", type number},
        {"product_height_cm", type number},
        {"product_width_cm", type number}
    }),
    
    // Merge with translation table
    MergedTranslation = Table.NestedJoin(
        TypedProducts, {"product_category_name"},
        translation_table, {"product_category_name"},
        "CategoryTranslation", JoinKind.LeftOuter
    ),
    
    ExpandedTranslation = Table.ExpandTableColumn(
        MergedTranslation, "CategoryTranslation",
        {"product_category_name_english"}, {"product_category_name_english"}
    ),
    
    // Coalesce missing translations
    CoalesceCategory = Table.AddColumn(ExpandedTranslation, "category_english", each 
        if [product_category_name_english] <> null and [product_category_name_english] <> "" 
        then [product_category_name_english]
        else if [product_category_name] <> null and [product_category_name] <> ""
        then [product_category_name]
        else "Unknown / Other", type text),
        
    // Format category: replace underscores with spaces and capitalize
    ReplaceUnderscores = Table.ReplaceValue(CoalesceCategory, "_", " ", Replacer.ReplaceText, {"category_english"}),
    FormattedCategory = Table.TransformColumns(ReplaceUnderscores, {{"category_english", Text.Proper, type text}}),
    
    // Remove temp raw english column
    FinalProducts = Table.RemoveColumns(FormattedCategory, {"product_category_name_english"})
in
    FinalProducts

