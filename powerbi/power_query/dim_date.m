// ============================================================
// DimDate — Power Query M Calendar Generation Script
// Range: 2016-01-01 to 2018-12-31 (Matches Olist dataset range)
// ============================================================

let
    StartDate = #date(2016, 1, 1),
    EndDate = #date(2018, 12, 31),
    DayCount = Duration.Days(EndDate - StartDate) + 1,
    DateList = List.Dates(StartDate, DayCount, #duration(1, 0, 0, 0)),
    TableFromList = Table.FromList(DateList, Splitter.SplitByNothing(), {"Date"}, null, ExtraValues.Error),
    ChangedType = Table.TransformColumnTypes(TableFromList, {{"Date", type date}}),
    
    // Add Calendar Attributes
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
    AddIsWeekend

