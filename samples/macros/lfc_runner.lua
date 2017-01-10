--[[ LuaFAR context runner ]]--

----------------------------------------
--[[ description:
  -- LuaFAR context package runner.
  -- Запускатель пакета LuaFAR context.
--]]
----------------------------------------
--[[ uses:
  none.
  -- group: Macros/Plugins.
--]]
--------------------------------------------------------------------------------
do
  -- Путь к профилю
  local GetSysEnv = win.GetEnv
  local ProfilePath = GetSysEnv("FARPROFILE")
  if not ProfilePath then
    ProfilePath = GetSysEnv("FARHOME").."\\Profile"

  end

  -- Путь к пакету
  local package = package
  local ModulePath = ProfilePath.."\\work\\?.lua;"
  local PackPath = package.path
  if not PackPath:find(ModulePath, 1, true) then
    package.path = ModulePath..PackPath

  end

  -- Инициализация пакета
  require "context.initiate"

  -- Установка обработчиков
  local Priority = Priority or 100
  local resident = require "context.resident"

  Event {
    group       = "EditorEvent",
    description = "LuaFAR context ProcessEditorEvent",
    priority    = Priority,

    action      = function (id, event, param)

      return resident.ProcessEditorEvent(id, event, param)

    end,

  } ---

  Event {
    group       = "ViewerEvent",
    description = "LuaFAR context ProcessViewerEvent",
    priority    = Priority,

    action      = function (id, event, param)

      return resident.ProcessViewerEvent(id, event, param)

    end,

  } ---

  Event {
    group       = "ExitFAR",
    description = "LuaFAR context ExitScript",
    priority    = Priority,

    action      = function ()

      return resident.ExitScript()

    end,

  } ---

end
--------------------------------------------------------------------------------
--return unit
--------------------------------------------------------------------------------
