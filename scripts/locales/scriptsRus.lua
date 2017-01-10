--[[ LuaFAR context ]]--
--[[ scripts: Russian ]]--
--[[ scripts: русский ]]--

--------------------------------------------------------------------------------
--local U = unicode.utf8.char
local BackInheritSign = '->' -- U(0x2192)

----------------------------------------
local Data = {

    -- config formation
    CWrongMerge  = "Неизвестный режим слияния",
    SWrongMerge  = [[
Неправильный режим:
{ base = '%s', merge = '%s' }.
Используется основная или пользовательская таблица конфигурации.]],
    CInvalidCfg  = "Неверный файл конфигурации",
    SInvalidCfg  = "Файл конфигурации '%s' содержит ошибки.\n%s",
    CNoUniqueCfg = "Нет уникального файла конфигурации",
    SNoUniqueCfg = "Не найдена уникальная конфигурация '%s' not found.",
    CNoBaseCfg   = "Нет основного файла конфигурации",
    SNoBaseCfg   = "Найден только пользовательский файл конфигурации '%s'.",
    CNoConfigs   = "Нет файлов конфигурации",
    SNoConfigs   = "Не найдены файлы конфигурации '%s'.",

    -- config access
    CNoRegConfig = "Нет конфигурации",
    SNoRegConfig = "Требуемая конфигурация '%s' не зарегистрирована.",
    CNoCfgTable  = "Нет таблицы конфигурации",
    SNoCfgTable  = "Требуемая конфигурация '%s' не является таблицей.",
    --CUsedMT_index = "Использование __index",
    --SUsedMT_index = "Метаполе __index конфигурации уже используется.",

    -- config register
    CRegError    = "Ошибка регистрации",
    SRegNoKey    = "Не указан ключ конфигурации.",
    SRegRepeat   = "Конфигурация '%s' уже зарегистрирована.",
    CUnRegError  = "Ошибка снятия с регистрации",
    SUnRegNoReg  = "Конфигурация '%s' не зарегистрирована.",
    SUnRegDiffer = "Отличающаяся конфигурация '%s' для снятия с регистрации.",

    ----------------------------------------
    -- areaFileType
    panelsArea  = 'Панели',
    editorArea  = 'Редактор',
    viewerArea  = 'Просмотр',
    unknownArea = 'Неизвестно',
    SNoAreaFunction = "Для области '%s' нет функции определения типа файла",
    --CPatternError   = "Ошибка в паттерне",
    --SInvalidPattern = 'Паттерн для типа "%s" - неправильный:\n%s',

    -- checkConfig
    CInheritError = "Ошибка наследования",
    SInheritDirect   = 'Тип "%s" наследует от самого себя по полю "%s".\n',
    SInheritUnknown  = 'Тип "%s" наследует от неизвестного типа "%s" по полю "%s".\n',
    SInheritIndirect = 'Тип "%s" наследует от самого себя по полю "%s". ',
    SInheritLostType = 'Значение для типа "%s" не найдено.',

    SInheritChainBegin = 'Последовательность: {',
    SInheritChainSep = BackInheritSign,
    SInheritChainEnd = '}.',
    SInheritReset = 'Наследование %s'..BackInheritSign..'%s сброшено.',

    ----------------------------------------
} --- Data

return Data
--------------------------------------------------------------------------------
