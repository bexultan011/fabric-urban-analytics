// Bronze: ECB daily USD/EUR exchange rate since 2015 → lh_bronze.dbo.ecb_fx_usd_eur

let
  Source = Csv.Document(Web.Contents("https://data-api.ecb.europa.eu/service/data/EXR/D.USD.EUR.SP00.A?format=csvdata&startPeriod=2015-01-01"), [Delimiter = ",", Columns = 32, QuoteStyle = QuoteStyle.None]),
  #"Promoted headers" = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
  #"Changed column type" = Table.TransformColumnTypes(#"Promoted headers", {{"KEY", type text}, {"FREQ", type text}, {"CURRENCY", type text}, {"CURRENCY_DENOM", type text}, {"EXR_TYPE", type text}, {"EXR_SUFFIX", type text}, {"TIME_PERIOD", type date}, {"OBS_VALUE", type number}, {"OBS_STATUS", type text}, {"OBS_CONF", type text}, {"OBS_PRE_BREAK", type text}, {"OBS_COM", type text}, {"TIME_FORMAT", type duration}, {"BREAKS", type text}, {"COLLECTION", type text}, {"COMPILING_ORG", type text}, {"DISS_ORG", type text}, {"DOM_SER_IDS", type text}, {"PUBL_ECB", type text}, {"PUBL_MU", type text}, {"PUBL_PUBLIC", type text}, {"UNIT_INDEX_BASE", type text}, {"COMPILATION", type text}, {"COVERAGE", type text}, {"DECIMALS", Int64.Type}, {"NAT_TITLE", type text}, {"SOURCE_AGENCY", type text}, {"SOURCE_PUB", type text}, {"TITLE", type text}, {"TITLE_COMPL", type text}, {"UNIT", type text}, {"UNIT_MULT", Int64.Type}}),
  #"Removed other columns" = Table.SelectColumns(#"Changed column type", {"CURRENCY", "CURRENCY_DENOM", "TIME_PERIOD", "OBS_VALUE"}),
  #"Renamed columns" = Table.RenameColumns(#"Removed other columns", {{"TIME_PERIOD", "rate_date"}, {"OBS_VALUE", "usd_per_eur"}, {"CURRENCY", "currency"}, {"CURRENCY_DENOM", "currency_denom"}}),
  #"Changed column type 1" = Table.TransformColumnTypes(#"Renamed columns", {{"rate_date", type date}, {"usd_per_eur", type number}})
in
  #"Changed column type 1"
