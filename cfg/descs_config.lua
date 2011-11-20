--[[ Main data ]]--

----------------------------------------
--[[ description:
  -- Type descriptions.
  -- Описания типов.
--]]
----------------------------------------
--[[ uses:
  nil.
  -- group: LF context.
--]]
--------------------------------------------------------------------------------
---------------------------------------- Abstract type descs
local abstract_type_descs = {
  _meta_  = { abstract = true },
      -- They usually haven't masks field!

  -- default
  --default = 'Default type',

  -- -- 0. special
  --special = 'Special type',
    none    = 'Unknown/undefined type',
    common  = 'Common predefined data (for any type)',
    ignore  = 'Private store for ignored data',
} --- abstract_type_descs

---------------------------------------- Available type descs
local type_descs = {
  _meta_ = { basis = 'base', merge = 'update' },

  -- 0. special

  -- 1. text

      -- 1.1. plain text

          -- 1.1.-. default text
              -- rare
              -- test

          -- 1.1.-. formed text
              -- Message:
              -- Others:

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
  edif = 'Electronic Design Interchange Format',
  bor_tem = 'Turbo Editor Macro language',
              -- Network data:
  css  = 'Cascading Style Sheets',
  sass = 'Syntactically Awesome Style Sheets',

          -- 1.2.3. markup text
  rtf  = 'Rich Text Format',
  --tex = '',
  --latex = '',
              -- rare
              -- FAR Manager & plugins:
  far  = 'FAR: File and ARchive Manager',
                  -- rare
              -- SGML subsets:
  sgml = 'Standard Generalized Markup Language',
  html = 'HyperText Markup Language',
  --xhtml = '',
                  -- rare
              -- XML main:
  xml  = 'Extensible Markup Language',
  --dtd = '',
  --xmlschema = '',
  --xslfo = '',
  --xslt = '',
  xquery  = 'XML Query language',
              -- XML book:
              -- XML others: -- MAYBE: somes are SGML subsets (MathML?)!
  --rdf = '',
                  -- rare

              -- SGML others:
                  -- rare
  --mathml = '',
  svg  = 'Scalable Vector Graphics',
  vrml = 'Virtual Reality Modelling Language',
  --wml = '',
  wsc  = 'Windows Script Components',
  --wsdl = '',
  wsf  = 'Windows Script Host',

              -- Colorer-take5:
  colorer = 'Colorer-take5',

      -- 1.3. source

          -- 1.3.1. language source

              -- 1.3.1.1. frequently used language
  fortran = 'FORmula TRANslation language',
  gpss = 'General Purpose Systems Simulator',
  idl  = 'Interface Definition Language',
  perl = 'Practical Extraction and Report Language',
                  -- rare
  lisp = 'List Processing',
                  -- Assembler other:
                  -- HDL:
  hdl  = 'Hardware Description Language',
  vhdl = 'Very high speed integrated circuit HDL',
                  -- ML:
  sml  = 'Standard Meta-Language',
                  -- Prolog:
                  -- Lexers:
  yacc = 'Yet Another Compiler - Compiler',
                  -- Java somes:

              -- 1.3.1.2. database language --
  sql  = 'Structured Query Language',
                  -- rare

              -- 1.3.1.-. .NET support language

              -- 1.3.1.3. network language
  php  = 'PHP: Hypertext Preprocessor',
                  -- 1.3.1.3.-. network script
                  -- 1.3.1.3.-. server pages

          -- 1.3.2. script language --
                  -- Lua:
  lua  = 'Lua',

              -- 1.3.2.1. batch/shell --
  shell  = 'SHell (Bourne shell)',
  ash    = 'Almquist SHell',
  csh    = 'C SHell',
  ksh    = 'Korn SHell',
  psh    = 'Perl SHell',
  zsh    = 'Z SHell',
  bash   = 'Bourne Again SHell',
  dash   = 'Debian Almquist SHell',
  fish   = 'Friendly Interactive SHell',
  tcsh   = 'Tenex C SHell',
                  -- rare
  jcl  = 'Job Control Language',

              -- 1.3.2.-. makefile
  scons = 'Software Construction tool',
                  -- rare
  awk  = 'Al Aho, Peter Weinberger, Brian Kernighan',

              -- 1.3.2.-. install script

  -- 2. packed

      -- 2.1. exec --

      -- 2.2. store --

          -- 2.2.1. arch --

          -- 2.2.2. disk --

      -- 2.3. media

          -- 2.3.1. image --

          -- 2.3.2. audio --
  midi = 'Musical Instrument Digital Interface',

          -- 2.3.3. video --

  -- 3. mixed

      -- 3.1. doc
  dvi = 'Device Independendent File',
  pdf = 'Portable Document Format',
              -- Composed help:
  hlp_rtf = 'Rich Text Format',
  hlp_chm = 'Compiled HTML help file',

      -- 3.2. font --
  tfm = 'TeX Font Metric',

      -- 3.3. others
} --- type_descs

---------------------------------------- main
setmetatable(type_descs, { __index = abstract_type_descs })

--------------------------------------------------------------------------------
return type_descs
--------------------------------------------------------------------------------
