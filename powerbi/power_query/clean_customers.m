// ============================================================
// clean_customers.m — Power Query M Transformation Script for Customers
// Source: MySQL olist_ecommerce.customers
// ============================================================

let
    Source = MySQL.Database("localhost:3306", "olist_ecommerce", [ReturnSingleDatabase=true]),
    customers_table = Source{[Schema="olist_ecommerce", Item="customers"]}[Data],
    
    TypedColumns = Table.TransformColumnTypes(customers_table, {
        {"customer_id", type text},
        {"customer_unique_id", type text},
        {"customer_zip_code_prefix", type text},
        {"customer_city", type text},
        {"customer_state", type text}
    }),
    
    // Normalize city names: trim and remove Portuguese special characters / diacritics
    TrimmedCity = Table.TransformColumns(TypedColumns, {{"customer_city", Text.Trim, type text}}),
    LowerCity = Table.TransformColumns(TrimmedCity, {{"customer_city", Text.Lower, type text}}),
    
    CleanCity1 = Table.ReplaceValue(LowerCity, "ã", "a", Replacer.ReplaceText, {"customer_city"}),
    CleanCity2 = Table.ReplaceValue(CleanCity1, "á", "a", Replacer.ReplaceText, {"customer_city"}),
    CleanCity3 = Table.ReplaceValue(CleanCity2, "à", "a", Replacer.ReplaceText, {"customer_city"}),
    CleanCity4 = Table.ReplaceValue(CleanCity3, "â", "a", Replacer.ReplaceText, {"customer_city"}),
    CleanCity5 = Table.ReplaceValue(CleanCity4, "é", "e", Replacer.ReplaceText, {"customer_city"}),
    CleanCity6 = Table.ReplaceValue(CleanCity5, "ê", "e", Replacer.ReplaceText, {"customer_city"}),
    CleanCity7 = Table.ReplaceValue(CleanCity6, "í", "i", Replacer.ReplaceText, {"customer_city"}),
    CleanCity8 = Table.ReplaceValue(CleanCity7, "ó", "o", Replacer.ReplaceText, {"customer_city"}),
    CleanCity9 = Table.ReplaceValue(CleanCity8, "ô", "o", Replacer.ReplaceText, {"customer_city"}),
    CleanCity10 = Table.ReplaceValue(CleanCity9, "õ", "o", Replacer.ReplaceText, {"customer_city"}),
    CleanCity11 = Table.ReplaceValue(CleanCity10, "ú", "u", Replacer.ReplaceText, {"customer_city"}),
    CleanCity12 = Table.ReplaceValue(CleanCity11, "ç", "c", Replacer.ReplaceText, {"customer_city"}),
    
    // Capitalize each word in city name
    ProperCity = Table.TransformColumns(CleanCity12, {{"customer_city", Text.Proper, type text}}),
    UppercaseState = Table.TransformColumns(ProperCity, {{"customer_state", Text.Upper, type text}})
in
    UppercaseState

