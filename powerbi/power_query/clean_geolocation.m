// ============================================================
// clean_geolocation.m — Deduplicated Geolocation Dimension
// Source: MySQL olist_ecommerce.geolocation (or CSV fallback)
// Deduplicates 1,000,163 raw rows down to ~19,015 unique zip codes
// ============================================================

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
    
    // Group by zip prefix to deduplicate and compute centroid lat/lng
    GroupedRows = Table.Group(TypedColumns, {"geolocation_zip_code_prefix"}, {
        {"latitude", each List.Average([geolocation_lat]), type number},
        {"longitude", each List.Average([geolocation_lng]), type number},
        {"city", each List.First([geolocation_city]), type text},
        {"state", each List.First([geolocation_state]), type text}
    }),
    
    // Clean city name
    TrimmedCity = Table.TransformColumns(GroupedRows, {{"city", Text.Trim, type text}}),
    ProperCity = Table.TransformColumns(TrimmedCity, {{"city", Text.Proper, type text}}),
    UpperState = Table.TransformColumns(ProperCity, {{"state", Text.Upper, type text}})
in
    UpperState

