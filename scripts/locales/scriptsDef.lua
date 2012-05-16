--[[ LuaFAR context ]]--
--[[ scripts: English ]]--

--------------------------------------------------------------------------------
--local U = unicode.utf8.char
local BackInheritSign = '->' -- U(0x2192)

----------------------------------------
local Data = {
    -- config formation
    CWrongMerge  = "Unknown merge mode",
    SWrongMerge  = [[
Incorrect mode:
{ base = '%s', merge = '%s' }.
Base or user config table is used.]],
    CInvalidCfg  = "Invalid config file",
    SInvalidCfg  = "Config file '%s' contains errors.\n%s",
    CNoUniqueCfg = "No unique config file",
    SNoUniqueCfg = "Unique config '%s' not found.",
    CNoBaseCfg   = "No base config file",
    SNoBaseCfg   = "User config '%s' file only found.",
    CNoConfigs   = "No config files",
    SNoConfigs   = "Config '%s' files not found.",

    -- config access
    CNoRegConfig = "No config",
    SNoRegConfig = "Required config '%s' is not registered.",
    CNoCfgTable  = "No config table",
    SNoCfgTable  = "Required config '%s' is not a table.",
    --CUsedMT_index = "Using __index",
    --SUsedMT_index = "Config's __index metafield is already used.",

    -- for config register
    CRegError    = "Register error",
    SRegNoKey    = "The key for config is not specified.",
    SRegRepeat   = "Config '%s' is already registered.",
    CUnRegError  = "Unregister error",
    SUnRegNoReg  = "Config '%s' is not registered.",
    SUnRegDiffer = "Unregistered config '%s' is different.",

    ----------------------------------------
    -- areaFileType
    panelsArea  = 'Panels',
    editorArea  = 'Editor',
    viewerArea  = 'Viewer',
    unknownArea = 'Unknown',
    SNoAreaFunction = "No filetype detect function for area '%s'",
    --CPatternError   = "Pattern error",
    --SInvalidPattern = 'Pattern for type "%s" is invalid:\n%s',

    -- checkConfig
    CInheritError = "Inherit error",
    SInheritDirect   = 'Type "%s" inherits from itself by field "%s".\n',
    SInheritUnknown  = 'Type "%s" inherits from unknown type "%s" by field "%s".\n',
    SInheritIndirect = 'Type "%s" inherits from itself by field "%s". ',
    SInheritLostType = 'Value for type "%s" is not found.',

    SInheritChainBegin = 'Chain: {',
    SInheritChainSep = BackInheritSign,
    SInheritChainEnd = '}.',
    SInheritReset = 'Inheritance %s'..BackInheritSign..'%s is reset.',

    ----------------------------------------
} --- Data

return Data
--------------------------------------------------------------------------------
