// ---- openaq_nyc_sensors ---

let
  api_Key = "5b0ec72eabd73700305502236ccd9c3b9172f87e0f319923c239f0eacc4610ea",
  Source = Json.Document(Web.Contents("https://api.openaq.org",[RelativePath="v3/locations", Query=[bbox = "-74.26,40.49,-73.70,40.92",
                    limit = "1000"], Headers=[#"X-API-Key"=api_Key]])),
  Navigation = Source[results],
  #"Converted to table" = Table.FromList(Navigation, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
  #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to table", "Column1", {"id", "name", "locality", "timezone", "country", "owner", "provider", "isMobile", "isMonitor", "instruments", "sensors", "coordinates", "licenses", "bounds", "distance", "datetimeFirst", "datetimeLast"}, {"id", "name", "locality", "timezone", "country", "owner", "provider", "isMobile", "isMonitor", "instruments", "sensors", "coordinates", "licenses", "bounds", "distance", "datetimeFirst", "datetimeLast"}),
  #"Removed other columns" = Table.SelectColumns(#"Expanded Column1", {"isMonitor", "name", "id", "sensors", "coordinates", "datetimeFirst", "datetimeLast"}),
  #"Renamed columns" = Table.RenameColumns(#"Removed other columns", {{"isMonitor", "is_monitor"}, {"name", "location_name"}, {"id", "location_id"}}),
  #"Expanded coordinates" = Table.ExpandRecordColumn(#"Renamed columns", "coordinates", {"latitude", "longitude"}, {"latitude", "longitude"}),
  #"Expanded datetimeFirst" = Table.ExpandRecordColumn(#"Expanded coordinates", "datetimeFirst", {"utc"}, {"utc"}),
  #"Expanded datetimeLast" = Table.ExpandRecordColumn(#"Expanded datetimeFirst", "datetimeLast", {"utc"}, {"utc.1"}),
  #"Renamed columns 1" = Table.RenameColumns(#"Expanded datetimeLast", {{"utc", "first_utc"}, {"utc.1", "last_utc"}}),
  #"Expanded sensors" = Table.ExpandListColumn(#"Renamed columns 1", "sensors"),
  #"Expanded sensors 1" = Table.ExpandRecordColumn(#"Expanded sensors", "sensors", {"id", "name", "parameter"}, {"id", "name", "parameter"}),
  #"Renamed columns 2" = Table.RenameColumns(#"Expanded sensors 1", {{"id", "sensor_id"}}),
  #"Expanded parameter" = Table.ExpandRecordColumn(#"Renamed columns 2", "parameter", {"id", "name", "units"}, {"id", "name.1", "units"}),
  #"Removed columns" = Table.RemoveColumns(#"Expanded parameter", {"name"}),
  #"Renamed columns 3" = Table.RenameColumns(#"Removed columns", {{"name.1", "parameter"}, {"id", "parameter_id"}}),
  #"Changed column type" = Table.TransformColumnTypes(#"Renamed columns 3", {{"first_utc", type datetime}, {"last_utc", type datetime}}),
  #"Filtered rows" = Table.SelectRows(#"Changed column type", each ([parameter] = "no2" or [parameter] = "pm25")),
  #"Filtered rows 2" = Table.SelectRows(#"Filtered rows", each [last_utc] > #datetime(2025, 1, 1, 0, 0, 0)),
  #"Changed column type 1" = Table.TransformColumnTypes(#"Filtered rows 2", {{"is_monitor", type logical}, {"location_id", Int64.Type}, {"parameter_id", Int64.Type}, {"latitude", type number}, {"longitude", type number}, {"sensor_id", Int64.Type}, {"location_name", type text}, {"parameter", type text}, {"units", type text}})
in
  #"Changed column type 1"

// function get sensor days 
(sensorId as number) as table =>
let
    apiKey = "5b0ec72eabd73700305502236ccd9c3b9172f87e0f319923c239f0eacc4610ea",
    Source = Json.Document(
        Web.Contents(
            "https://api.openaq.org",
            [
                RelativePath = "v3/sensors/" & Number.ToText(sensorId) & "/days",
                Query = [
                    date_from = "2025-01-01",
                    date_to = Date.ToText(Date.From(DateTime.LocalNow()), "yyyy-MM-dd"),
                    limit = "1000"
                ],
                Headers = [#"X-API-Key" = apiKey]
            ]
        )
    ),
    Results = Source[results],
    AsTable = Table.FromList(Results, Splitter.SplitByNothing(), {"Column1"})
in
    AsTable

//openaq sensor days 

let
  Source = openaq_nyc_sensors,
  #"Removed other columns" = Table.SelectColumns(Source, {"is_monitor", "location_id", "sensor_id", "parameter", "units"}),
  #"Invoked custom function" = Table.AddColumn(#"Removed other columns", "days", each fnGetSensorDays([sensor_id]), type table),
  #"Expanded days" = Table.ExpandTableColumn(#"Invoked custom function", "days", {"Column1"}, {"Column1"}),
  #"Expanded Column1" = Table.ExpandRecordColumn(#"Expanded days", "Column1", {"value", "period", "coverage"}, {"value", "period", "coverage"}),
  #"Expanded period" = Table.ExpandRecordColumn(#"Expanded Column1", "period", {"datetimeFrom"}, {"datetimeFrom"}),
  #"Expanded datetimeFrom" = Table.ExpandRecordColumn(#"Expanded period", "datetimeFrom", {"local"}, {"local"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Expanded datetimeFrom", {{"local", type datetimezone}}),
  #"Expanded coverage" = Table.ExpandRecordColumn(#"Changed column type", "coverage", {"percentComplete"}, {"percentComplete"}),
  #"Renamed columns" = Table.RenameColumns(#"Expanded coverage", {{"percentComplete", "coverage_pct"}, {"value", "avg_value"}}),
  #"Changed column type 1" = Table.TransformColumnTypes(#"Renamed columns", {{"avg_value", type number}, {"coverage_pct", type number}, {"local", type text}}),
  #"Renamed columns 1" = Table.RenameColumns(#"Changed column type 1", {{"local", "date_local"}}),
  #"Filtered rows" = Table.SelectRows(#"Renamed columns 1", each [avg_value] <> null and [avg_value] <> "")
in
  #"Filtered rows"
