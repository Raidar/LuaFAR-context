--[[ Main data ]]--

----------------------------------------
--[[ description:
  -- Information about language names/codes.
  -- Информация о названиях/обозначениях языков.
--]]
----------------------------------------
--[[ uses:
  nil.
  -- group: Locale.
--]]
--------------------------------------------------------------------------------

----------------------------------------
local languages = {} -- Languages

--------------------------------------------------------------------------------

---------------------------------------- Self-names
-- Language names in language itself:
languages.alpha = {
  default = "default",
  --chinese = "",
  czech = "čeština",
  english = "english",
  french = "français",
  german  = "deutsch",
  hungarian = "magyar",
  italian = "italiano",
  japanese = "nippon",
  polish = "polski",
  portuguese = "português",
  russian = "русский",
  spanish = "español",
  -- etc / и т.д.
  esperanto = "esperanto",
} -- alpha

---------------------------------------- Two-letter codes
-- alpha-2 / ISO 639-1 Code
languages.alpha_2 = {
  default = "__",
  chinese = "zh",
  czech = "cs",
  english = "en",
  french = "fr",
  german  = "de", -- "ge"
  hungarian = "hu",
  italian = "it",
  japanese = "ja",
  polish = "pl",
  portuguese = "pt",
  russian = "ru",
  spanish = "es", -- "sp"
  -- etc / и т.д.
  esperanto = "eo",
} -- alpha_2

---------------------------------------- Three-letter codes
-- alpha-3 / ISO 639-2 Code
languages.alpha_3 = {
  default = "def",
  chinese = "zho",
  czech = "ces", -- "cze"
  english = "eng",
  french = "fra", -- "fre"
  german  = "ger", -- "deu"
  hungarian = "hun",
  italian = "ita",
  japanese = "jpn", -- "jap"
  polish = "pol",
  portuguese = "por",
  russian = "rus",
  spanish = "spa", -- "esp"
  -- etc / и т.д.
  esperanto = "epo",
} -- alpha_3

--------------------------------------------------------------------------------
return languages
--------------------------------------------------------------------------------
