// ==============================================================================
// MASTER POWER QUERY (M) INGESTION & ETL SCRIPT
// Project: Olist E-Commerce Analytics (MySQL to Power BI)
// Target Database: localhost:3306 / olist_ecommerce
// ==============================================================================

/*
SETUP INSTRUCTIONS:
1. In Power BI Desktop: Home -> Transform Data -> Power Query Editor.
2. In View Tab: Enable "Column quality", "Column distribution", and "Column profile".
3. Change profiling from "Based on top 1000 rows" to "Column profiling based on entire dataset".
4. For each table below, click New Source -> Blank Query -> Advanced Editor -> Paste the code snippet.
*/

// ─────────────────────────────────────────────────────────────────────────────
// 1. DIM_DATE (Standard Date Dimension covering 2016 to 2018)
// ─────────────────────────────────────────────────────────────────────────────
// Query Name: DimDate
let
    StartDate = #date(2016, 1, 1),
    EndDate = #date(2018, 12, 31),
    DayCount = Duration.Days(EndDate - StartDate) + 1,
    DateList = List.Dates(StartDate, DayCount, #duration(1, 0, 0, 0)),
    TableFromList = Table.FromList(DateList, Splitter.SplitByNothing(), {"Date"}, null, ExtraValues.Error),
    ChangedType = Table.TransformColumnTypes(TableFromList, {{"Date", type date}}),
    AddDateKey = Table.AddColumn(ChangedType, "DateKey", each Date.Year([Date]) * 10000 + Date.Month([Date]) * 100 + Date.Day([Date]), Int64.Type),
    AddYear = Table.AddColumn(AddDateKey, "Year", each Date.Year([Date]), Int64.Type),
    AddQuarter = Table.AddColumn(AddYear, "Quarter", each "Q" & Text.From(Date.QuarterOfYear([Date])), type text),
    AddYearQuarter = Table.AddColumn(AddQuarter, "YearQuarter", each Text.From([Year]) & "-Q" & Text.From(Date.QuarterOfYear([Date])), type text),
    AddMonth = Table.AddColumn(AddYearQuarter, "MonthNumber", each Date.Month([Date]), Int64.Type),
    AddMonthName = Table.AddColumn(AddMonth, "MonthName", each Date.MonthName([Date]), type text),
    AddMonthShort = Table.AddColumn(AddMonthName, "MonthShort", each Text.Start([MonthName], 3), type text),
    AddYearMonth = Table.AddColumn(AddMonthShort, "YearMonth", each Text.From([Year]) & "-" & Text.PadStart(Text.From([MonthNumber]), 2, "0"), type text),
    AddDay = Table.AddColumn(AddYearMonth, "DayOfMonth", each Date.Day([Date]), Int64.Type),
    AddDayOfWeek = Table.AddColumn(AddDay, "DayOfWeekNumber", each Date.DayOfWeek([Date], Day.Monday) + 1, Int64.Type),
    AddDayName = Table.AddColumn(AddDayOfWeek, "DayOfWeekName", each Date.DayOfWeekName([Date]), type text),
    AddIsWeekend = Table.AddColumn(AddDayName, "IsWeekend", each if [DayOfWeekNumber] >= 6 then true else false, type logical)
in
    AddIsWeekend;

// ─────────────────────────────────────────────────────────────────────────────
// 2. DIM_CUSTOMERS (Cleaned customer dimension with accent-stripped cities)
// ─────────────────────────────────────────────────────────────────────────────
// Query Name: olist_customers
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
    TrimmedCity = Table.TransformColumns(TypedColumns, {{"customer_city", Text.Trim, type text}}),
    LowerCity = Table.TransformColumns(TrimmedCity, {{"customer_city", Text.Lower, type text}}),
    CleanAccents = Table.ReplaceValue(
        Table.ReplaceValue(
        Table.ReplaceValue(
        Table.ReplaceValue(
        Table.ReplaceValue(
        Table.ReplaceValue(
        Table.ReplaceValue(
        Table.ReplaceValue(
        Table.ReplaceValue(
        Table.ReplaceValue(
        Table.ReplaceValue(
        Table.ReplaceValue(LowerCity, "ã", "a", Replacer.ReplaceText, {"customer_city"}),
        "á", "a", Replacer.ReplaceText, {"customer_city"}),
        "à", "a", Replacer.ReplaceText, {"customer_city"}),
        "â", "a", Replacer.ReplaceText, {"customer_city"}),
        "é", "e", Replacer.ReplaceText, {"customer_city"}),
        "ê", "e", Replacer.ReplaceText, {"customer_city"}),
        "í", "i", Replacer.ReplaceText, {"customer_city"}),
        "ó", "o", Replacer.ReplaceText, {"customer_city"}),
        "ô", "o", Replacer.ReplaceText, {"customer_city"}),
        "õ", "o", Replacer.ReplaceText, {"customer_city"}),
        "ú", "u", Replacer.ReplaceText, {"customer_city"}),
        "ç", "c", Replacer.ReplaceText, {"customer_city"}),
    ProperCity = Table.TransformColumns(CleanAccents, {{"customer_city", Text.Proper, type text}}),
    UppercaseState = Table.TransformColumns(ProperCity, {{"customer_state", Text.Upper, type text}})
in
    UppercaseState;

// ─────────────────────────────────────────────────────────────────────────────
// 3. DIM_PRODUCTS (Cleaned products merged with English category names)
// ─────────────────────────────────────────────────────────────────────────────
// Query Name: olist_products
let
    Source = MySQL.Database("localhost:3306", "olist_ecommerce", [ReturnSingleDatabase=true]),
    products_table = Source{[Schema="olist_ecommerce", Item="products"]}[Data],
    translation_table = Source{[Schema="olist_ecommerce", Item="product_category_translation"]}[Data],
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
    MergedTranslation = Table.NestedJoin(TypedProducts, {"product_category_name"}, translation_table, {"product_category_name"}, "CategoryTranslation", JoinKind.LeftOuter),
    ExpandedTranslation = Table.ExpandTableColumn(MergedTranslation, "CategoryTranslation", {"product_category_name_english"}, {"product_category_name_english"}),
    CoalesceCategory = Table.AddColumn(ExpandedTranslation, "category_english", each 
        if [product_category_name_english] <> null and [product_category_name_english] <> "" 
        then [product_category_name_english]
        else if [product_category_name] <> null and [product_category_name] <> ""
        then [product_category_name]
        else "Unknown / Other", type text),
    ReplaceUnderscores = Table.ReplaceValue(CoalesceCategory, "_", " ", Replacer.ReplaceText, {"category_english"}),
    FormattedCategory = Table.TransformColumns(ReplaceUnderscores, {{"category_english", Text.Proper, type text}}),
    FinalProducts = Table.RemoveColumns(FormattedCategory, {"product_category_name_english"})
in
    FinalProducts;

// ─────────────────────────────────────────────────────────────────────────────
// 4. DIM_SELLERS (Cleaned sellers table with normalized cities)
// ─────────────────────────────────────────────────────────────────────────────
// Query Name: olist_sellers
let
    Source = MySQL.Database("localhost:3306", "olist_ecommerce", [ReturnSingleDatabase=true]),
    sellers_table = Source{[Schema="olist_ecommerce", Item="sellers"]}[Data],
    TypedColumns = Table.TransformColumnTypes(sellers_table, {
        {"seller_id", type text},
        {"seller_zip_code_prefix", type text},
        {"seller_city", type text},
        {"seller_state", type text}
    }),
    TrimmedCity = Table.TransformColumns(TypedColumns, {{"seller_city", Text.Trim, type text}}),
    LowerCity = Table.TransformColumns(TrimmedCity, {{"seller_city", Text.Lower, type text}}),
    CleanAccents = Table.ReplaceValue(
        Table.ReplaceValue(
        Table.ReplaceValue(
        Table.ReplaceValue(LowerCity, "ã", "a", Replacer.ReplaceText, {"seller_city"}),
        "á", "a", Replacer.ReplaceText, {"seller_city"}),
        "é", "e", Replacer.ReplaceText, {"seller_city"}),
        "ó", "o", Replacer.ReplaceText, {"seller_city"}),
    ProperCity = Table.TransformColumns(CleanAccents, {{"seller_city", Text.Proper, type text}}),
    UppercaseState = Table.TransformColumns(ProperCity, {{"seller_state", Text.Upper, type text}})
in
    UppercaseState;

// ─────────────────────────────────────────────────────────────────────────────
// 5. DIM_GEOLOCATION (Deduplicated 19,015 unique zip codes from 1M rows)
// ─────────────────────────────────────────────────────────────────────────────
// Query Name: olist_geolocation
let
    Source = MySQL.Database("localhost:3306", "olist_ecommerce", [ReturnSingleDatabase=true]),
    geo_table = Source{[Schema="olist_ecommerce", Item="geolocation"]}[Data],
    TypedColumns = Table.TransformColumnTypes(geo_table, {
        {"geolocation_zip_code_prefix", type text},
        {"geolocation_lat", type number},
        {"geolocation_lng", type number},
        {"geolocation_city", type text},
        {"geolocation_state", type text}
    }),
    GroupedRows = Table.Group(TypedColumns, {"geolocation_zip_code_prefix"}, {
        {"latitude", each List.Average([geolocation_lat]), type number},
        {"longitude", each List.Average([geolocation_lng]), type number},
        {"city", each List.First([geolocation_city]), type text},
        {"state", each List.First([geolocation_state]), type text}
    })
in
    GroupedRows;

// ─────────────────────────────────────────────────────────────────────────────
// 6. FACT_SALES (Core analytical fact view from MySQL)
// ─────────────────────────────────────────────────────────────────────────────
// Query Name: fact_sales
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
    TypedColumns;

