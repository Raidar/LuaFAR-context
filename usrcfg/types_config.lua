--[[ User data ]]--

----------------------------------------
--[[ description:
  -- Used types.
  -- Используемые типы.
--]]
--------------------------------------------------------------------------------
local types = {
  --_meta_ = { merge = 'update' },
  --_meta_ = { basis = 'base', merge = 'update' },
  _meta_ = { basis = 'base', merge = 'asmeta' },
  --_meta_ = { basis = 'user', merge = 'asmeta' },
  -- 1. text

      -- 1.1. plain text --

      -- 1.1. plain text

          -- 1.1.-. default text
              -- rare
              -- test
  ___ = { inherit = 'txt', desc = '___ text file', masks = {'%.___$'} },
  --_itself_ = { inherit = '_itself_', desc = '_itself_ inherit' },
  --_indir_1_ = { inherit = '_indir_2_', desc = '_indirect_ inherit 1' },
  --_indir_2_ = { inherit = '_indir_1_', desc = '_indirect_ inherit 2' },

          -- 1.1.-. formed text
              -- Message:
              -- Others:
  ctxdic   = { inherit = 'define', desc = 'Context 3.x dictionary',
               masks = {'%.dic$'} },
  readme   = { inherit = 'ini', desc = 'Ini-like ReadMe', group = 'plain',
               masks = {'%.rm[ekit]$','%.rdme?$','%.readme$'} },
  --[[
    rdm — общее описание.
    rme — (конкретное) описание.
    rmi (index) — индекс.
    rmt (text) — текст.
    rmk (k??) — ?.
  --]]

      -- 1.2. rich text

          -- 1.2.1. config text
              -- FAR Manager & plugins:
              -- System config:
              -- Windows config:

          -- 1.2.2. data define
              -- Resources:
              -- Subtitles:
                  -- rare
              -- Script data:
                  -- FAR Manager & plugins:
                  -- rare
              -- Network data:

          -- 1.2.3. markup text
              -- rare
              -- FAR Manager & plugins:
                  -- rare
              -- SGML subsets:
                  -- rare
              -- XML main:
              -- XML book:
              -- XML others:
                  -- rare
              -- SGML others:
                  -- rare
              -- Colorer-take5:

      -- 1.3. source

          -- 1.3.1. language source

              -- 1.3.1.1. frequently used language
                  -- rare
                  -- Assembler other:
                  -- HDL:
                  -- ML:
                  -- Prolog:
                  -- Lexers:
                  -- Java somes:

              -- 1.3.1.2. database language --
                  -- rare

              -- 1.3.1.-. .NET support language

              -- 1.3.1.3. network language
                  -- 1.3.1.3.-. network script
                  -- 1.3.1.3.-. server pages

          -- 1.3.2. script language --
                  -- Lua:
  lua_lum = { inherit = 'lua', desc = 'Lua User Menu',
              masks = {'%.lum$'}, firstline = {'-- LUM'} },

              -- 1.3.2.1. batch/shell --
                  -- rare

              -- 1.3.2.-. makefile
                  -- rare

              -- 1.3.2.-. install script

  -- 2. packed

      -- 2.1. exec --

      -- 2.2. store --

          -- 2.2.1. arch --

          -- 2.2.2. disk --

      -- 2.3. media

          -- 2.3.1. image --

          -- 2.3.2. audio --

          -- 2.3.3. video --

  -- 3. mixed

      -- 3.1. doc
              -- Composed help:

      -- 3.2. font --

      -- 3.3. others
} --- types

return types
--------------------------------------------------------------------------------
