// Bronze: World Bank GDP (current US$) for USA, 2000–2025 → lh_bronze.dbo.worldbank_gdp

let
  Source = Json.Document(Web.Contents("https://api.worldbank.org/v2/country/USA/indicator/NY.GDP.MKTP.CD?format=json&date=2000:2025&per_page=100")),
  #"Converted to table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
  Navigation = #"Converted to table"{1}[Column1],
  #"Converted to table 1" = Table.FromList(Navigation, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
  #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to table 1", "Column1", {"indicator", "country", "countryiso3code", "date", "value", "unit", "obs_status", "decimal"}, {"indicator", "country", "countryiso3code", "date", "value", "unit", "obs_status", "decimal"}),
  #"Expanded indicator" = Table.ExpandRecordColumn(#"Expanded Column1", "indicator", {"value"}, {"value.1"}),
  #"Expanded country" = Table.ExpandRecordColumn(#"Expanded indicator", "country", {"value"}, {"value.2"}),
  #"Removed columns" = Table.RemoveColumns(#"Expanded country", {"unit", "obs_status", "decimal"}),
  #"Renamed columns" = Table.RenameColumns(#"Removed columns", {{"value.1", "indicator_name"}, {"value.2", "country_name"}, {"countryiso3code", "country_code"}, {"date", "year"}, {"value", "gdp_usd"}}),
  #"Changed column type" = Table.TransformColumnTypes(#"Renamed columns", {{"year", Int64.Type}, {"gdp_usd", type number}, {"country_code", type text}, {"country_name", type text}, {"indicator_name", type text}})
in
  #"Changed column type"
