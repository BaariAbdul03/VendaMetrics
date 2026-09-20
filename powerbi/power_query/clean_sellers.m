// ============================================================
// clean_sellers.m — Power Query M Transformation Script for Sellers
// Source: MySQL olist_ecommerce.sellers
// ============================================================

let
    Source = MySQL.Database("localhost:3306", "olist_ecommerce", [ReturnSingleDatabase=true]),
    sellers_table = Source{[Schema="olist_ecommerce", Item="sellers"]}[Data],
    
    TypedColumns = Table.TransformColumnTypes(sellers_table, {
        {"seller_id", type text},
        {"seller_zip_code_prefix", type text},
        {"seller_city", type text},
        {"seller_state", type text}
    }),
    
    // Normalize city names
    TrimmedCity = Table.TransformColumns(TypedColumns, {{"seller_city", Text.Trim, type text}}),
    LowerCity = Table.TransformColumns(TrimmedCity, {{"seller_city", Text.Lower, type text}}),
    
    CleanCity1 = Table.ReplaceValue(LowerCity, "ã", "a", Replacer.ReplaceText, {"seller_city"}),
    CleanCity2 = Table.ReplaceValue(CleanCity1, "á", "a", Replacer.ReplaceText, {"seller_city"}),
    CleanCity3 = Table.ReplaceValue(CleanCity2, "à", "a", Replacer.ReplaceText, {"seller_city"}),
    CleanCity4 = Table.ReplaceValue(CleanCity3, "â", "a", Replacer.ReplaceText, {"seller_city"}),
    CleanCity5 = Table.ReplaceValue(CleanCity4, "é", "e", Replacer.ReplaceText, {"seller_city"}),
    CleanCity6 = Table.ReplaceValue(CleanCity5, "ê", "e", Replacer.ReplaceText, {"seller_city"}),
    CleanCity7 = Table.ReplaceValue(CleanCity6, "í", "i", Replacer.ReplaceText, {"seller_city"}),
    CleanCity8 = Table.ReplaceValue(CleanCity7, "ó", "o", Replacer.ReplaceText, {"seller_city"}),
    CleanCity9 = Table.ReplaceValue(CleanCity8, "ô", "o", Replacer.ReplaceText, {"seller_city"}),
    CleanCity10 = Table.ReplaceValue(CleanCity9, "õ", "o", Replacer.ReplaceText, {"seller_city"}),
    CleanCity11 = Table.ReplaceValue(CleanCity10, "ú", "u", Replacer.ReplaceText, {"seller_city"}),
    CleanCity12 = Table.ReplaceValue(CleanCity11, "ç", "c", Replacer.ReplaceText, {"seller_city"}),
    
    ProperCity = Table.TransformColumns(CleanCity12, {{"seller_city", Text.Proper, type text}}),
    UppercaseState = Table.TransformColumns(ProperCity, {{"seller_state", Text.Upper, type text}})
in
    UppercaseState

