--[[ LuaFAR context ]]--

----------------------------------------
--[[ description:
  -- Working with localization.
  -- Работа с локализацией.
--]]
----------------------------------------
--[[ uses:
  LuaFAR,
  LF context.
  -- group: Locale, Datas.
--]]
--------------------------------------------------------------------------------
local _G = _G

local pairs = pairs
local setmetatable = setmetatable

----------------------------------------
local context, ctxdata = context, ctxdata

local utils  = context.utils
local tables = context.tables
local datas  = context.datas

----------------------------------------
--local logMsg = (require "Rh_Scripts.Utils.Logging").Message

--------------------------------------------------------------------------------
local unit = {}

----------------------------------------
local lCodes = ctxdata.languages.alpha_3

---------------------------------------- Messages
local Msgs = {
  -- getData:
  locFileError = "Locale data file:\n%s",
  defFileError = "Default data file:\n%s",
  -- getDual:
  curFileError = "Current data files:\n%s",
  genFileError = "General data files:\n%s",
} --- Msgs

---------------------------------------- Prepare
-- Get localized text.
-- Получение локализованного текста.
function unit.text (Data, Index) --> (string | nil)
  return Index and Data[Index] or Index
end ----

do
  local initcap = utils.initcap

-- Get codes for used languages
-- Получение "кодов" используемых языков.
function unit.language () --> (table, table)
  local lang = utils.language()
  local codes, s = {}
  for k, v in pairs(lang) do
    s = lCodes[v:lower()] -- Код языка
    if s then codes[k] = initcap(s) end
  end

  return lang, codes
end ----

end -- do

----------------------------------------
local f_fname = '%s%s%s'

-- Check and get full file name with localization.
-- Проверка и получение полного имени файла с локализацией.
--[[ Параметры:
  path (string) - путь до файла локализации.
  name (string) - общая часть имени файла.
  loc  (string) - добавление к имени файла.
  ext  (string) - расширение файла (без точки).
--]]
function unit.filename (path, name, loc) --> (string | nil)
  return f_fname:format(path, name, loc)
end ----
local locfname = unit.filename

-- Check and get full file names with localization + by default.
-- Проверка и получение полных имён файлов с локализацией + по умолчанию.
--[[ Параметры:
  см. unit.filename.
--]]
function unit.bothname (path, name, loc) --> (string/nil, string/nil)
  return loc and locfname(path, name, loc), locfname(path, name, 'Def')
end ----

-- Customize localization settings.
-- Настройка установок локализации.
function unit.customize (Custom) --> (table)
  local u = Custom.locale
  u.lang, u.codes   = unit.language()
  u.help, u.defhelp = unit.bothname(u.path, u.file, u.codes.Help)
  u.name, u.defname = unit.bothname(u.path, u.file, u.codes.Main)
  --logMsg(Custom, 'Custom', 2, '#q')

  return Custom
end ----

---------------------------------------- Data
-- Make data with Custom settings.
-- Формирование данных по установкам Custom.
--[[ Параметры:
  Custom (table) - установки скрипта.
  name  (string) - общая часть имени файла.
  t  (table|nil) - уже существующая таблица данных.
--]]
function unit.makeData (Custom, name, t) --> (table | nil, error)
  local Locale = Custom.locale
  if Locale.kind == 'require' then
    return datas.require(name, t)
  elseif Locale.kind == 'load' then
    return datas.load(utils.fullname(Custom.base, name, Locale.ext), t)
  else
    return datas.make(Custom.base, name, Locale.ext, t)
  end
end ----

do
  local type = type
  local _makeData = unit.makeData

-- Get locale data with Custom settings.
-- Получение данных локализации по установкам Custom.
--[[ Параметры:
  Custom   (table) - установки скрипта.
  locBasis (table) - существующая таблица данных локализации.
  defBasis (table) - существующая таблица данных по умолчанию.
--]]
function unit.getData (Custom, locBasis, defBasis) --> (table | nil, errors)
  local Locale, defData, defError = Custom.locale
  if type(Custom.defdata) == 'table' then defData = Custom.defdata
  else  defData, defError = _makeData(Custom, Locale.defname, defBasis) end
  local locData, locError = _makeData(Custom, Locale.name, locBasis)
  --[[
  if defData then logMsg(defData, 'defData', 1, '#q') end
  if locData then logMsg(locData, 'locData', 1, '#q') end
  --]]

  if defData then -- Make data hierarchy:
    if not locData then return defData end
    locData.__index = defData
    return setmetatable(locData, locData)

  elseif locData then
    return locData
  end

  return nil, defError and Msgs.defFileError:format(defError),
              locError and Msgs.locFileError:format(locError)
end ----

  local _getData = unit.getData

-- Get locale data with double settings.
-- Получение данных локализации по двойному набору установок.
--[[ Параметры:
  Custom    (table) - текущие установки скрипта.
  genCustom (table) - общие установки скрипта.
  ... - остальные параметры unit.getData для текущих установок.
--]]
function unit.getDual (Custom, genCustom, ...) --> (table)
  -- TODO: Use both error messages from getData!
  local curData, curError = _getData(Custom, ...) -- current
  local genData, genError = _getData(genCustom)   -- general
  --[[
  if curData then
    logMsg({ curData = curData,
             defData = curData.__index }, 'curData', 1, '#q')
  end
  if genData then
    logMsg({ genData = genData,
             defData = genData.__index }, 'genData', 1, '#q')
  end
  --]]

  if genData then -- Make data hierarchy:
    if not curData then return genData end
    local idxData = curData.__index or curData
    idxData.__index = genData
    --[[
    local gi_Data = (genData or tables.NULL).__index
    logMsg({ idxData = idxData, genData = genData,
             gi1Data = gi_Data,
             gi2Data = (gi_Data or tables.NULL).__index,
            }, 'idxData', 1, '#qtfn') -- '#q')
    --]]
    return setmetatable(idxData, idxData)

  elseif curData then
    return curData
  end

  return nil, curError and Msgs.curFileError:format(curError),
              genError and Msgs.genFileError:format(genError)
end ----

end -- do

-- Prepare localization data for script by its settings.
-- Подготовка данных локализации для скрипта по его установкам.
function unit.prepare (Custom, ...) --> (table)
  local Custom = unit.customize(Custom) -- Localization customizing
  return unit.getData(Custom, ...)  -- Localization data for Custom
end ----

-- Localize data for script by its settings.
-- Локализация данных для скрипта по его установкам.
function unit.localize (Custom, defCustom, ...) --> (table)
  local Custom = datas.customize(Custom, defCustom) -- Common customize
  return unit.prepare(Custom, ...)  -- Prepare localization data
end ----

---------------------------------------- Class
local TLocale = {} -- Класс локализации
local Locale_MT = { __index = TLocale }

-- Make a localization class object.
-- Формирование объекта класса локализации.
--[[ Параметры:
  Custom   (table) - установки скрипта.
  Data     (table) - данные локализации.
  useError  (bool) - показ сообщения об ошибке вместо его возврата.
  show      (func) - функция вывода сообщения (по умолчанию far.Message)
                     параметры функции: (текст, [заголовок], [флаги]).
     Результат:
  объект с методами локализации.
--]]
function unit.make (Custom, Data, useError, show) --> (object)
  local self = {
    Custom = Custom,
    Data = Data or {},
    useError = useError,
    _show = show or utils.warning,
  } ---
  Custom.Locale = self

  return setmetatable(self, Locale_MT)
end ----

-- Create a localization object for script with its parameters.
-- Создание объекта локализации для скрипта с учётом его параметров.
function unit.create (Custom, defCustom, ...) --> (object)
  local Data, e1, e2 = unit.localize(Custom, defCustom, ...)
  if Data then return unit.make(Custom, Data) end

  return nil, e1, e2
end ----

-- Update a localization object.
-- Обновление объекта локализации.
-- Warning: It is for getData only, not for getDual.
function TLocale:update () --> (object)
  local Data, e1, e2 = unit.prepare(self.Custom)
  if Data then
    self.Data = Data
    return self
  end

  return nil, e1, e2
end ----

-- Free a localization object.
-- Освобождение объекта локализации.
function TLocale:free () --| (object)
  self.Data = nil
  self.Custom = nil
  self = nil
end ----

-- Show localization error message.
-- Показ сообщения об ошибке локализации.
function unit.showError (...)
  return utils.warning('Localization', utils.concat(...), 'l')
end ----

---------------------------------------- Methods
local loctext = unit.text

-- Get localized text.
-- Получение локализованного текста.
function TLocale:text (Index) --> (string)
  return loctext(self.Data, Index)
end ----

-- Get text with detailed remark.
-- Получение текста с подробным пояснением.
function TLocale:t1 (Index, ...)
  return self:text(Index):format(...)
end ----

-- Get text with embedded remark.
-- Получение текста с вложенным пояснением.
function TLocale:t2 (Index1, Index2, ...)
  return self:text(Index1):format(self:text(Index2), ...)
end ----

-- Output warning text.
-- Вывод текста-предупреждения.
function TLocale:warning (title, text, flags) --| (message)
  return self._show(title, text, flags and flags..'w' or 'w')
end ----

-- Output simple warning text.
-- Вывод простого текста-предупреждения.
function TLocale:w0 (IndexT, IndexM, flags)
  return self:warning(self:text(IndexT), self:text(IndexM), flags)
end ----

-- Output warning text with detailed remark.
-- Вывод текста-предупреждения с подробным пояснением.
function TLocale:w1 (IndexT, IndexM, ...)
  return self:warning(self:text(IndexT), self:t1(IndexM, ...))
end ----

-- Output warning text with embedded remark.
-- Вывод текста-предупреждения с вложенным пояснением.
function TLocale:w2 (IndexT, Index1, Index2, ...)
  return self:warning(self:text(IndexT), self:t2(Index1, Index2, ...))
end ----

-- Output text with error.
-- Вывод текста об ошибке.
function TLocale:error (text, flags) --| (message)
  return self:warning(self:text'Error', text, flags)
end ----

-- Output error text with detailed remark.
-- Вывод текста об ошибке с подробным пояснением.
function TLocale:e1 (Index, ...)
  return self:error(self:t1(Index, ...))
end ----

-- Output error text with embedded remark.
-- Вывод текста об ошибке с вложенным пояснением.
function TLocale:e2 (Index1, Index2, ...)
  return self:error(self:t2(Index1, Index2, ...))
end ----

-- Messages/texts about errors.
-- Сообщения/тексты об ошибках.
function TLocale:et1 (Index, ...)
  return (self.useError and self.e1 or self.t1)(self, Index, ...)
end ----

function TLocale:et2 (Index1, Index2, ...)
  return (self.useError and self.e2 or self.t2)(self, Index1, Index2, ...)
end ----

---------------------------------------- Specials
-- Methods with short names.
-- Методы с короткими именами.
do
  local shortText = { -- Default items text:
    t = 'text',
    M = 'text',
    w = 'warning',
    W = 'warning',
    e = 'error',
    E = 'error',
  } ---

  for k, v in pairs(shortText) do TLocale[k] = TLocale[v] end

end -- do

----------------------------------------
-- Autogenerated methods that uses prefixes.
-- Автогенерируемые методы, которые используют префиксы.
do
  local defText = { -- Default items text:
    dialog  = 'dlg_', --> dialog
    caption = 'cap_', --> caption (dialog box)
    config  = 'cfg_', --> config dialog / config item
    -- dialog items:
    sep     = 'sep_', --> separator
    label   = 'lbl_', --> text / vtext (label)
    item    = 'itm_', --> listbox / combobox item
    group   = 'grp_', --> singlebox / groupbox
    button  = 'btn_', --> button
    box     = 'box_', --> checkbox / radiobutton
    --edt     = 'edt_', --> edit/fixedit/pswedit
    --user    = 'usr_', --> user control
  } ---
  for k, v in pairs(defText) do
    TLocale[k] = function (self, Index)
      return self:text(v..Index)
    end
  end

  local fmtText = { -- Formatted text:
    fmtsep = { 'sep_', ' %s '   }, --> separator
    fmtbtn = { 'btn_', '[ %s ]' }, --> button
    defbtn = { 'btn_', '{ %s }' }, --> default button
    dlgbtn = { 'btn_', '< %s >' }, --> showdialog button
  } ---
  for k, v in pairs(fmtText) do
    if not defText[k] then -- no rewrite!
      TLocale[k] = function (self, Index)
        return v[2]:format(self:text(v[1]..Index))
      end
    end
  end

end -- do

--------------------------------------------------------------------------------
context.locale = unit -- 'locale' table in context
--------------------------------------------------------------------------------
