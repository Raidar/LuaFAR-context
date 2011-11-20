# LuaFAR plugin: makefile

# ---- user's settings -------------------------------------------------------

# Location of LuaFAR base directory
PATH_LUAFAR = ..\..\luafar_unicode

# Name of LuaFAR plugin
TARGET      = lf_plugin.dll

# Supported export functions
EXPORTS = \
  -DEXPORT_OPENPLUGINW         \
  -DEXPORT_PROCESSEDITOREVENTW \
  -DEXPORT_PROCESSVIEWEREVENTW

# ---- end of user's settings ------------------------------------------------

include $(PATH_LUAFAR)/src/luaplug.mak

#----- end of makefile -------------------------------------------------------
