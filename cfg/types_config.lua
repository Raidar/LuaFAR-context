--[[ Main data ]]--

----------------------------------------
--[[ description:
  -- Used types.
  -- Используемые типы.
--]]
----------------------------------------
--[[ uses:
  nil.
  -- group: Config, Datas.
--]]
----------------------------------------
--[[ used:
  Miettunen J. Filex Offline.
  -[El. res].- El. text data.
  2000.
--]]
--------------------------------------------------------------------------------

---------------------------------------- Used parts
local lines = { -- firstlines:
  ini = '^[;%[]',
  ini_ext = '^[;#%[]',
  assa = '%[Script Info%]',
  asm_rem = '^%s*;',
  c_rem = '^%s*/[/%*]',
  pas_rem = '^%s*{',
  lua_rem = '^%s*%-%-',
  s_inc = '#include',
  s_def = '#define',
  s_if  = '#if',
  xml = '^<%?xml',
  -- firstlines' common parts:
  lang = 'language%s*=.-',
  dtd_xhtml = 'DTD XHTML%s.-',
} --- lines

local masks = { -- masks:
  inc = '%.inc$',
  html = '%.[^ptr]?html?$',
  xhtml = '%.x?html?$',
  asp_as = '%.as[pa]$',
  asp_ht = '%.ht[rxa]$',
} --- masks

local msets = { -- masks' sets:
  xhtml  = {masks.xhtml},
  asp    = {masks.asp_as, masks.asp_ht, masks.inc},
  modula = {'[%(<]%*', 'MODULE', 'DEFINITION', 'IMPLEMENTATION'},
} --- msets

---------------------------------------- Abstract types
local abstract_types = {
  _meta_  = { abstract = true },
      -- They usually haven't masks field!

  -- default
  default = { desc = 'Default type', }, -- abstract

  -- -- 0. special
  special = { inherit = 'default', desc = 'Special type', },
    none    = { inherit = 'special', desc = 'None type', },
    common  = { inherit = 'special', desc = 'Commmon data', },
    --accept  = { inherit = 'special', desc = 'Accepted data', },
    ignore  = { inherit = 'special', desc = 'Ignored data',
                skiplines = { ['^%s-$'] = false, ['^<%?xml'] = 'xml', },
              }, -- for empty, xml, etc

  -- -- 1. text (typescript)
  text    = { inherit = 'default', desc = 'Text type', },
    plain   = { inherit = 'text', desc = 'Plain text', },       -- 1.1. straight
    rich    = { inherit = 'text', desc = 'Rich text', },        -- 1.2. formatted
      config  = { inherit = 'rich', desc = 'Config text', },
      define  = { inherit = 'rich', desc = 'Data define', },
      markup  = { inherit = 'rich', desc = 'Markup text', },
    source  = { inherit = 'text', desc = 'Source language', },  -- 1.3.
      main    = { inherit = 'source', desc = 'Main language', },
        dbl     = { inherit = 'main', desc = 'Database language', },
        net     = { inherit = 'main', desc = 'Network language', },
      script  = { inherit = 'source', desc = 'Script language', },
        shell   = { inherit = 'script', desc = 'Shell/batch language', },
      -- types below is recommended for 'group' field only:
      rare    = { inherit = 'main', desc = 'Seldom used language', },

  -- -- 2. packed (no text)
  packed  = { inherit = 'default', desc = 'Packed type', },
    exec    = { inherit = 'packed', desc = 'Executable code', },-- 2.1.
    store   = { inherit = 'packed', desc = 'Packed storage', }, -- 2.2.
      arch    = { inherit = 'store', desc = 'File archive', },
      disk    = { inherit = 'store', desc = 'Disk image', },
    media   = { inherit = 'packed', desc = 'Multimedia data', },-- 2.3.
      image   = { inherit = 'media', desc = 'Graphic data', },
      audio   = { inherit = 'media', desc = 'Audio data', },
      video   = { inherit = 'media', desc = 'Video data', },

  -- -- 3. mixed (text + packed)
  mixed   = { inherit = 'default', desc = 'Mixed type', },
    doc     = { inherit = 'mixed', desc = 'Document data', },   -- 3.1.
    font    = { inherit = 'mixed', desc = 'Font data', },       -- 3.2.
} --- abstract_types

---------------------------------------- Available types
local types = {
  _meta_  = { basis = 'base', merge = 'update', },
  -- They usually are real or auxiliary types.

  -- 0. special
  empty     = { inherit = 'special', desc = 'Empty', },
  back      = { inherit = 'special', desc = '".."', masks = {'[/\\]?%.%.$'}, },
  dir       = { inherit = 'special', desc = 'Directory', path = '[/\\].+[/\\]$', },

  -- 1. text

      -- 1.1. plain text --

          -- 1.1.-. default text
  txt       = { inherit = 'plain', desc = 'Text',
                masks = {'%.txt$','%.ans$','%.asc$'}, },
    txt_lang  = { inherit = 'txt', desc = 'Locale text',
                  masks = {'%.rus$','%.eng$'}, },
    txt_spec  = { inherit = 'txt', desc = 'Special text',
                  masks = {'%.nfo$','%.spo$','%.___$','%.!!!$'}, },
    txt_dist  = { inherit = 'txt', desc = 'Install text', -- Distribution kit
                  masks = {'^read%.?me$','^faq.-$',
                           '^install.-$','^todo.-$',
                           '^.-changelog.-$','^copying.-$',
                           '^license.-$','^authors.-$'}, },
              -- rare
  --mancolorer= { inherit = 'text', desc = 'man colorer', masks = {'^man%s?colorer$'}, },
              -- test (used in typesTest.lua)
  tst_def   = { inherit = 'plain', desc = 'Test: Default text', masks = {'%.tst$'}, },
    tst_fl1   = { inherit = 'tst_def', desc = 'Test: fl #1 text',
                  --masks = {'%.tst$'}, firstline = {'line #1'}, },
                  masks = {'%.tst$'}, strongline = {'line #1'}, },
    tst_fl2   = { inherit = 'tst_def', desc = 'Test: fl #2 text',
                  --masks = {'%.tst$'}, firstline = {'line #2'}, },
                  masks = {'%.tst$'}, strongline = {'line #2'}, },

          -- 1.1.-. formed text
              -- Message:
  message   = { inherit = 'plain', desc = 'Message', },
    msg_fido  = { inherit = 'message', desc = 'FIDO message', masks = {'%.msg$','%.uue$'}, },
    msg_eml   = { inherit = 'message', desc = 'E-mail message',
                  masks = {'%.eml$','%.msg$','%.nws$'}, firstline = {'^FROM'}, },
    msg_pkt   = { inherit = 'message', desc = 'PKTview message', masks = {'%.pms$'}, },
    msg_far   = { inherit = 'message', desc = 'FARMail message',
                  masks = {'%.msg$','%.eml$','%.nsw$'}, firstline = {'%%start%%'}, },
              -- Others:
  filedesc  = { inherit = 'plain', desc = 'File description',
                masks = {'file_id%.diz','descript%.ion', 'files%.bbs'}, },
  irclog    = { inherit = 'plain', desc = 'IRC log', masks = {'%.irclog$'}, },

      -- 1.2. rich text --

          -- 1.2.1. config text --
  ini       = { inherit = 'config', desc = 'INI config',
                masks = {'%.ini$','%.cfg$'}, },
  --ini_ini   = { inherit = 'config', desc = 'Main config',
  --              masks = {'%.ini$','%.cfg$'}, firstline = {lines.ini}, },
    ini_cfg   = { inherit = 'ini', desc = 'Other config',
                  masks = {'%.ctl$','%.tpl$','%.srg$','%.lng$',
                           --'%.conf$', -- xml-based config
                           '%.gitconfig$',
                           '%.types$','%.tab$'},
                  firstline = {lines.ini_ext}, },
              -- Lua somes:
  cfg_lua   = { inherit = 'config', desc = 'Lua-ini config',
                masks = {'%.ltx$'}, firstline = {lines.ini}, },

    ini_dlf   = { inherit = 'ini', desc = 'Delphi ini', -- Delphi config:
                  masks = {'%.dof$','%.dsk$','%.dro$','%.dci$'},
                  firstline = {lines.ini}, },

              -- FAR Manager & plugins:
  lng_far   = { inherit = 'config', desc = 'FAR lng',
                masks = {'%.lng$'}, firstline = {'^%.Language'}, },
    ini_far   = { inherit = 'ini', desc = 'FAR ini',
                  masks = {'%.farini$'}, firstline = {lines.ini}, },
    --reg_far   = { inherit = 'reg', desc = 'FAR reg', masks = {'%.farreg$'}, },

              -- System config:
  cfg_sys   = { inherit = 'config', desc = 'System config', },
    sys_boot  = { inherit = 'cfg_sys', desc = 'Boot.ini',
                 masks = {'boot%.ini$'}, firstline = {'%[boot%sloader%]'}, },
    sys_dos   = { inherit = 'cfg_sys', desc = 'MsDos.sys', masks = {'^msdos%.sys'}, },
    sys_cfg   = { inherit = 'cfg_sys', desc = 'Config.sys', masks = {'^config%.sys'}, },
             -- Windows config:
    inf       = { inherit = 'sys_cfg', desc = 'Windows INF',
                  masks = {'%.inf$'}, firstline = {lines.ini}, },
    reg       = { inherit = 'sys_cfg', desc = 'Windows REG', masks = {'%.reg$'},
                firstline = {'^%s*REGEDIT4%s*$','^%s-FARREG%d%d%s*$',
                             '^%s*Windows Registry Editor Version %d%.%d%d%s*$'}, },

          -- 1.2.2. data define --
              -- Resources:
  --[[ -- MAYBE:
  res_def   = { inherit = 'define', desc = 'Resource define', },
    res_src   = { inherit = 'res_def', desc = 'Resource source', masks = {'%.rc$','%.dlg$'}, },
    frm_dlf   = { inherit = 'res_def', desc = 'Delphi form', masks = {'%.dfm$'}, },
  --]]
  frm_dlf   = { inherit = 'define', desc = 'Delphi form', masks = {'%.dfm$'}, },
  res_src   = { inherit = 'define', desc = 'Resource source', masks = {'%.rc$','%.dlg$'}, },
  vmodeler  = { inherit = 'define', desc = 'Visual Modeler', masks = {'%.mdl$'}, },

              -- Subtitles:
  sub       = { inherit = 'define', desc = 'Subtitles', },
    sub_assa  = { inherit = 'sub', desc = '(Advanced) Sub Station Alpha', group = 'ini',
                  masks = {'%.ass$','%.ssa$'},
                  firstline = {'^'..lines.assa,'^...'..lines.assa}, },
    sub_srt   = { inherit = 'sub', desc = 'SubRipper', group = 'ini',
                  masks = {'%.srt$'}, firstline = {'^%d+'}, },
    sub_sub   = { inherit = 'sub', desc = 'SubViewer/SubMagic/etc', group = 'sub_srt',
                  masks = {'%.sub$'}, firstline = {'^%[%w+%]'}, },
                  -- rare
  --[[
    sub_jaco  = { inherit = 'sub', desc = 'JACOsub',
                  masks = {'%.js$'}, firstline = {'^# JACOsub script file'}, },
    sub_pjs   = { inherit = 'sub', desc = 'Phoenix Japanimation Society',
                  masks = {'%.pjs$'}, },
    sub_qt    = { inherit = 'sub', desc = 'QTtext', group = 'ini',
                  masks = {'%.txt$'}, firstline = {'^{QTtext}'}, },
    sub_s2k   = { inherit = 'sub', desc = 'Sasami2k',
                  masks = {'%.s2k$'}, firstline = {'Sasami'}, },
  --]]
  --[[
    sub_mdv   = { inherit = 'sub', desc = 'MicroDVD',
                  masks = {'%.txt$','%.sub$'}, firstline = {''}, }, -- Unknown firstline!
    sub_tmps  = { inherit = 'sub', desc = 'TMPlayer subtritres',
                  masks = {'%.sub$'}, firstline = {''}, }, -- Unknown firstline!
  -- unknown sub format for: masks = {'%.mpl$'}
  --]]
  --[[
    sub_sgml  = { inherit = 'sgml', desc = 'SGML subtitle', group = 'sub', },
    sub_sami  = { inherit = 'sub_sgml', desc = 'Microsoft SAMI'
                  masks = {'%.smi$'}, firstline = {'^%s*<SAMI>'}, },
    sub_smil  = { inherit = 'sub_sgml', desc = 'W3C SMIL',
                  masks = {'%.smil?$'}, firstline = {'^%s*<smil>'}, },
    sub_rt    = { inherit = 'sub_smil', desc = 'W3C RealText',
                  masks = {'%.rt$'}, firstline = {'^%s*<window%s+'}, },
  --]]

              -- Script data:
  scriptdata= { inherit = 'define', desc = 'Script data', group = 'script', },
    diff      = { inherit = 'scriptdata', desc = 'Diff/Patch',
                  masks = {'%.diff?.*$','%.pat$','%.patch$','%.rej$','%.reject$'},
                  firstline = {'^diff','^Index','^%-%-%-','^%+%+%+','^%*%*%*',
                               '^%d+,%d+%w%d ','^ %d+%w%d','^cvs'}, },
                  -- FAR Manager & plugins:
  def_far   = { inherit = 'scriptdata', desc = 'FAR define', },
  airbrush  = { inherit = 'def_far', desc = 'FAR Airbrush', masks = {'[/\\%.]syntax$'}, },
  truemac   = { inherit = 'def_far', desc = 'FAR True Macro', masks = {'%truemac%.ctl$'}, },
                  -- rare
  -- [[
  aditor    = { inherit = 'define', desc = 'Aditor highlight', masks = {'%.hgh$'}, },
  edif      = { inherit = 'define', desc = 'EDIF', masks = {'%.edi?f$','%.ed[no]$'}, },
  step_rc   = { inherit = 'define', desc = 'Litestep step_rc', masks = {'step%.rc$'}, },

  bor_tem   = { inherit = 'scriptdata', desc = 'TEM language', masks = {'%.tem$'}, },
  m4        = { inherit = 'scriptdata', desc = 'M4 macro processor', masks = {'%.m4$'}, },
  mntrack   = { inherit = 'scriptdata', desc = 'MNTrack script', masks = {'%.scn$'}, },
  --]]

              -- Network data:
  netdata   = { inherit = 'define', desc = 'Network script data', },
  css       = { inherit = 'netdata', desc = 'CSS', group = 'html', masks = {'%.css$'}, },
  sass      = { inherit = 'css', desc = 'SASS', group = 'haml', masks = {'%.sass$'}, },
  less      = { inherit = 'css', desc = 'LESS', group = 'haml', masks = {'%.less$'}, },

          -- 1.2.3. markup text --
  markdown  = { inherit = 'markup', desc = 'Markdown', masks = {'%.md$'}, },
  
  rtf       = { inherit = 'markup', desc = 'RTF', masks = {'%.rtf$'}, },
  tex       = { inherit = 'markup', desc = 'TeX',
                masks = {'%.tex$','%.sty$','%.cls$'},
                firstline = {'^%s-%%'}, }, -- <-^ ??
  latex     = { inherit = 'tex', desc = 'LaTeX',
                masks = {'%.lt[xr]$','%.dtx$'}, },
  postscript= { inherit = 'markup', desc = 'PostScript',
                masks = {'%.ps[1-3f]?$','%.eps[if]?$','%.gsf$'},
                strongline = {'^%%!PS'}, firstline = {'^%%!'}, },
  ps_font   = { inherit = 'postscript', desc = 'Postscript Font', group = 'font',
                masks = {'%.pf[ab]$'}, firstline = {'^%%!','^%%!PS'}, },

  haml      = { inherit = 'markup', desc = 'HAML', masks = {'%.haml$'}, },
  yaml      = { inherit = 'markup', desc = 'YAML', masks = {'%.yaml$'}, },
  json      = { inherit = 'yaml', desc = 'JSON', masks = {'%.json$'}, },

  relaxnc   = { inherit = 'markup', desc = 'Relax NG Compact Syntax', group = "RELAX",
                masks = {'%.rnc$'}, },
              -- rare
  --[[
  admtempl  = { inherit = 'main', desc = 'ADM - Policy Template', masks = {'%.adm$'}, },
  linkdef   = { inherit = 'main', desc = 'Link Defines', masks = {'%.def$'}, },
  pmscript  = { inherit = 'main', desc = 'PageMaker Script', masks = {'%.spt$'}, },
  --]]
              -- FAR Manager & plugins:
  far       = { inherit = 'markup', desc = 'FAR type', },
  far_hlf   = { inherit = 'far', desc = 'FAR Help',
                masks = {'%.hlf$'}, firstline = {'^%.Language'}, },
  farmenu   = { inherit = 'far', desc = 'FAR Menu',
                masks = {'%.farmenu.?%.ini$'}, },
                  -- rare
  --[[
  far_eum   = { inherit = 'far', desc = 'FAR EditorUserMenu', masks = {'%.eum$'}, },
  far_tgs   = { inherit = 'far', desc = 'FAR Html editor', group = 'xml',
               masks = {'%.tgs$'}, },
  --]]
              -- SGML subsets:
  sgml      = { inherit = 'markup', desc = 'SGML subset', },
  html      = { inherit = 'sgml', desc = 'HTML', masks = {masks.html}, },
  html_doc  = { inherit = 'html', desc = 'HTML doc', masks = {masks.html},
                firstline = {'^%s*<!DOCTYPE%s+HTML',
                             '^%s*<HTML', '^%s*<!%-%-'}, },
  xhtml     = { inherit = 'html', desc = 'XHTML',
                masks = msets.xhtml }, -- , firstline = {lines.xml}
  xhtml_f   = { inherit = 'xhtml', desc = 'XHTML Frameset',
                masks = msets.xhtml,
                firstline = {lines.dtd_xhtml..'Frameset'}, },
  xhtml_s   = { inherit = 'xhtml', desc = 'XHTML Strict',
                masks = msets.xhtml,
                firstline = {lines.dtd_xhtml..'Strict'}, },
  xhtml_t   = { inherit = 'xhtml', desc = 'XHTML Transitional',
                masks = msets.xhtml,
                firstline = {lines.dtd_xhtml..'Transitional'}, },

  parser    = { inherit = 'html', desc = 'Parser', group = 'asp',
                masks = {'%.html?$','%.p$'}, firstline = {'^[@%^]%w+'}, },
                  -- rare
  -- [[
  mason     = { inherit = 'html', desc = 'Mason', group = 'perl', masks = {'%.mc$'}, },
  ppwizard  = { inherit = 'html', desc = 'ppWizard', masks = {'%.i[th]$'}, },
  --]]
              -- XML main:
  xml       = { inherit = 'sgml', desc = 'XML', masks = {'%.xml$'}, },
  xml_doc   = { inherit = 'xml', desc = 'XML doc',
                masks = {'%.xml$','%.gi2$','%.gpr$'},
                firstline = {lines.xml,'xmlns','<!DOCTYPE','^%s*<%w%w->%s*'}, },
                --..'%s+%w+%s*=%*[\'\"].-[\'\"]%s*' -- more complex check
  dtd       = { inherit = 'xml', desc = 'DTD',
                masks = {'%.dtd$','%.ent$','%.mod$'}, },
  xmlschema = { inherit = 'xml', desc = 'XML Schema', masks = {'%.xsd?$'}, },
  xslfo     = { inherit = 'xml', desc = 'XSL-FO',
                masks = {'%.xsltfo?$','%.fo$'}, }, -- 1.0
  xslt      = { inherit = 'xml', desc = 'XSLT', masks = {'%.xslt?2?$'},
                firstline = {'stylesheet%s+',
                             '[tT]ransform%s+'}, }, -- 1.0 & 2.0
              -- use colorer' proto.hrc for XSLT 1.0 and XSLT 2.0 separation
  xquery    = { inherit = 'xml', desc = 'XQuery',
                masks = {'%.xq$'}, firstline = {'^%s*xquery%s+'}, },
              -- XML book:
  xmlbook   = { inherit = 'xml', desc = 'XML Book', },
  docbook   = { inherit = 'xmlbook', desc = 'DocBook',
                masks = {'%.dbk?$','%.docbook$'},
                firstline = {'DocBook XML','DOCTYPE article',
                             '<book','<article'}, },
  fb2       = { inherit = 'xmlbook', desc = 'FictionBook',
                masks = {'%.fb2$'}, firstline = {'FictionBook xmlns'}, },
              -- XML others: -- MAYBE: somes are SGML subsets (MathML?)!
  calcset   = { inherit = 'xml', desc = 'FAR calcset',
                masks = {'calcset%.csr$'}, },
  htc       = { inherit = 'xml', desc = 'HTC', masks = {'%.htc$'}, },
  rdf       = { inherit = 'xml', desc = 'RDF', masks = {'%.rdf$'}, },
  relaxng   = { inherit = 'xml', desc = 'Relax NG', group = "RELAX", masks = {'%.rng$'}, },
  rss       = { inherit = 'xml', desc = 'RSS', -- 0.91 & 1.0
                masks = {'^rss','%.rss$','%.rdf$','%.xml$'},
                firstline = {'xmlns="http://purl%.org/rss/1%.0/"',
                             '<rss version="0%.91">'}, },
  svg       = { inherit = 'xml', desc = 'SVG', masks = {'%.svg$'}, }, -- 1.0
  taglib    = { inherit = 'xml', desc = 'JSP taglib', group = 'jsp', masks = {'%.tld$'}, },
  web_app   = { inherit = 'xml', desc = 'web-app', masks = {'web%.xml$'}, },
  wsc       = { inherit = 'xml', desc = 'WSC', masks = {'%.wsc$'}, },
  wsdl      = { inherit = 'xml', desc = 'WSDL', masks = {'%.wsdl$'}, },
  wsf       = { inherit = 'xml', desc = 'WSF', masks = {'%.wsf$'}, },
  xbl       = { inherit = 'xml', desc = 'Mozilla XBL', masks = {'%.xml$'},
                firstline = {'xmlns%s*=%s*["\']http://www%.mozilla%.org/xbl["\']'}, },
  xsieve    = { inherit = 'xslt', desc = 'XSieve XSLT', masks = {'%.xsl$'},
                firstline = {'xmlns%s*=%s*["\']http://www%.sourceforge%.net["\']'}, },
                  -- rare
  --[[
  ant       = { inherit = 'xml', desc = 'Ant\'s build',
                masks = {'build%.xml$'}, firstline = {'<project'}, },
  --]]
              -- SGML others:
  vrml      = { inherit = 'sgml', desc = 'VRML', masks = {'%.wrl$'}, },
  wml       = { inherit = 'sgml', desc = 'WML', masks = {'%.wml$'}, },
                  -- rare
  -- [[
  mathml    = { inherit = 'sgml', desc = 'MathML',
                masks = {'%.mml$','%.math?$'},
                firstline = {'MathML'}, }, -- 2.0
  micqlog   = { inherit = 'sgml', desc = 'mICQ log', group = 'text',
                masks = {'^[%._]log$'}, firstline = {'^<$'}, },
  sdml      = { inherit = 'sgml', desc = 'SDML', masks = {'%.sdml$'}, },
  --]]
              -- Colorer-take5:
  colorer   = { inherit = 'xml', desc = 'Colorer', },
  clr_hrc   = { inherit = 'colorer', desc = 'Colorer HRC', masks = {'%.hrc$'}, },
  clr_hrd   = { inherit = 'colorer', desc = 'Colorer HRD', masks = {'%.hrd$'}, },
  clr_ent   = { inherit = 'colorer', desc = 'Colorer Entities',
                masks = {'%.ent%.hrc$','%.proto%.hrc$'}, },
  --clr_bkt   = { inherit = 'colorer', desc = 'Colorer bracket',
  --              masks = {'%.bkt%'}, },
  clr5cat   = { inherit = 'colorer', desc = 'Colorer5 catalog',
                masks = {'catalog%.xml$'},
                firstline = {'DTD Colorer CATALOG'}, },
  clr_x2h   = { inherit = 'colorer', desc = 'xsd2hrc.custom',
                masks = {'custom%..-%.xml$'},
                firstline = {'uri:colorer:custom'}, },

      -- 1.3. source --

          -- 1.3.1. language source --

              -- 1.3.1.1. frequently used language
  asm       = { inherit = 'main', desc = 'Assembler',
                masks = {'%.asm$','%.mac$','%.cod$'}, },
  asm_inc   = { inherit = 'asm', masks = {masks.inc,'%.i16$','%.i32$'},
                firstline = {lines.asm_rem}, },
  basic     = { inherit = 'main', desc = 'Basic', masks = {'%.bas$'}, },
  vb        = { inherit = 'basic', desc = 'Visual Basic',
                masks = {'%.bas$','%.vbp$','%.frm$','%.cls$'},
                firstline = {'^VERSION %d+%.%d+', '^VBWIZARD %d+%.%d+'}, },
  --[[ -- MAYBE:
  c         = { inherit = 'main', desc = 'C',
                masks = {'%.[ch]$','%.[ch]pp$','%.cc$','%.hh$','%.cxx$'}, },
  --]]
  c         = { inherit = 'main', desc = 'C', masks = {'%.[ch]$'}, },
  cpp       = { inherit = 'c', desc = 'C++',
                masks = {'%.[ch]pp$','%.cc$','%.hh$','%.cxx$'},
                strongline = {lines.c_rem, lines.s_inc, lines.s_def, lines.s_if},
              }, -- use firstline -^ (from colorer) for fine choice
  d         = { inherit = 'main', desc = 'D', masks = {'%.di?$'}, },
  forth     = { inherit = 'main', desc = 'Forth',
                masks = {'%.[4f]th$','%.f32$','%.spf$'}, }, -- ,'%.f$'
  fortran   = { inherit = 'main', desc = 'Fortran',
                masks = {'%.for$','%.f$','%.f90$','%.f77$'},
                firstline = {'^%*', '^C'}, }, -- conflict -^
  go        = { inherit = 'c', desc = 'Go', masks = {'%.go$'}, },
  idl       = { inherit = 'main', desc = 'IDL',
                masks = {'%.hvs$','%.[io]dl$'},
                firstline = {lines.c_rem, lines.s_inc}, },
  java      = { inherit = 'main', desc = 'Java',
                masks = {'%.java$','%.ja[vd]$'},
                strongline = {'^%// Decompiled by Jad'}, },
  pascal    = { inherit = 'main', desc = 'Pascal',
                masks = {'%.~?pas$','%.~?[bdlp]p[rk]$','%.pp$'},
                firstline = {'program','library','unit','package'}, },
  pas_inc   = { inherit = 'pascal',
                masks = {masks.inc,'%.i16$','%.i32$','%.int$'}, },
  perl      = { inherit = 'main', desc = 'Perl',
                masks = {'%.pl[sx]?$','%.pm$','%.pod$','%.t$','%.cgi$'},
                strongline = {'^#!%s-%S*perl'}, firstline = {'perl'}, },
  python    = { inherit = 'main', desc = 'Python',
                masks = {'%.py[ws]?$'},
                strongline = {'^#!%s-%S*python'}, },
  ruby      = { inherit = 'main', desc = 'Ruby',
                masks = {'%.rbw?$','%.ruby$','%.rake$','Rakefile$'},
                strongline = {'^#!%s-%S*ruby','%-%*%- ruby %-%*%-'},
                --[[firstline = {'%-%*%- ruby %-%*%-'},]] },
  scala     = { inherit = 'main', desc = 'Scala', masks = {'%.scala$'}, },
                    -- Wirth langs:
  modula    = { inherit = 'main', desc = 'Modula', group = 'pascal',
                masks = {'%.mod$','%.def$'}, firstline = msets.modula, },
  oberon    = { inherit = 'modula', desc = 'Oberon',
                masks = {'%.ob2?$','%.odf$'}, firstline = msets.modula, },
                    -- rare
  ada       = { inherit = 'main', desc = 'Ada', masks = {'%.ad[sbc]$'}, },
  eiffel    = { inherit = 'main', desc = 'Eiffel', masks = {'%.e$'}, },
  erlang    = { inherit = 'main', desc = 'Erlang', masks = {'%.[eh]rl$'}, },
  gpss      = { inherit = 'main', desc = 'GPSS', masks = {'%.gps$'}, },
  icon      = { inherit = 'main', desc = 'Icon', masks = {'%.icn$'}, },
  lisp      = { inherit = 'main', desc = 'Lisp',
                masks = {'%.li?sp$','%.scm$','%.elc?$'}, },
  matlab    = { inherit = 'main', desc = 'MatLab', masks = {'%.m$'}, },
  -- [[
                  -- Others:
  abap4     = { inherit = 'main', desc = 'ABAP/4', group = 'rare',
                masks = {'%.abap4?$'}, }, -- unknown
  cache     = { inherit = 'main', desc = 'Cache/Open-M', group = 'rare',
                masks = {'%.rsa$','%.ro$','%.rtn$','%.in[ct]$','%.mac$','%.cdl$'},
                firstline = {'^Cache[^%^]-%^IN[CT][^%^]-%^.-$', -- firstline?
                            '^OpenM[^%^]-%^IN[CT][^%^]-%^.-$',
                            '^Cache[^%^]-%^MAC[^%^]-%^.-$',
                            '^OpenM[^%^]-%^MAC[^%^]-%^.-$'}, }, -- unknown
  cobol     = { inherit = 'main', desc = 'Cobol', group = 'rare',
                masks = {'%.cob$','%.cbl$'}, },
  dssp      = { inherit = 'main', desc = 'DSSP', group = 'rare',
                masks = {'%.dsp$'}, firstline = {'PROGRAM'}, }, -- unknown
  --]]
  --[[
                  -- Assemblers:
  assem     = { inherit = 'asm', desc = 'Special asm', group = 'rare', },
  adsp      = { inherit = 'assem', desc = 'ADSP-21xx asm',
                masks = {'%.dsp$'}, }, -- ,'%.sys$' -- unknown
  asm8051   = { inherit = 'assem', desc = '8051 MCU asm', masks = {'%.a5[12]$'}, },
  avrasm    = { inherit = 'assem', desc = 'AVR MCU asm',
                masks = {'%.asm$','%.avr$','%.inc$'}, firstline = {'^%s*;'}, },
  picasm    = { inherit = 'assem', desc = 'PicAsm', masks = {'%.asm$','%.pic$'}, },
  z80asm    = { inherit = 'assem', desc = 'Z80 asm: za', masks = {'%.za$'}, },
  zasm80    = { inherit = 'assem', desc = 'Z80 asm: a80', masks = {'%.a80$'}, },
  --]]
  -- [[
                  -- HDL:
  hdl       = { inherit = 'main', desc = 'HDL', group = 'rare', },
  ahdl      = { inherit = 'hdl', desc = 'AHDL', masks = {'%.ahdl$','%.td[fo]$'}, },
  vhdl      = { inherit = 'hdl', desc = 'VHDL', masks = {'%.vhdl?$'}, },
  verilog   = { inherit = 'hdl', desc = 'Verilog', masks = {'%.g?v$'}, },
  --]]
  -- [[
                  -- ML:
  ml        = { inherit = 'main', desc = 'Meta-Language', group = 'rare', },
  sml       = { inherit = 'ml', desc = 'Standard ML', masks = {'%.sml$','%.sig$'}, },
  ocaml     = { inherit = 'ml', desc = 'Objective Caml', masks = {'%.ml[ilpy]?$'}, },
  --]]
  -- [[
                  -- Prolog:
  prolog    = { inherit = 'main', desc = 'Prolog', group = 'rare', },
  sprolog   = { inherit = 'prolog', desc = 'Sicstus Prolog', masks = {'%.pl$'}, },
  tprolog   = { inherit = 'prolog', desc = 'Turbo Prolog', masks = {'%.tpl$'}, },
  --]]
                  -- Lexers:
  lex       = { inherit = 'main', desc = 'Lex/flex', masks = {'%.f?lex$','%.l+$'}, },
  yacc      = { inherit = 'lex', desc = 'YACC/Bison', masks = {'%.yacc$','%.y+$'}, },
                  -- Java somes:
  j_pnuts   = { inherit = 'java', desc = 'Java Pnuts', masks = {'%.pnut$'}, },
  j_jcc     = { inherit = 'java', desc = 'Java Compiler Compiler', masks = {'%.jjt?$'}, },
  j_props   = { inherit = 'java', desc = 'Java properties',
                masks = {'%.prop?$','%.properties$'}, },
  j_policy  = { inherit = 'java', desc = 'Java policy', masks = {'%.policy$'}, },

              -- 1.3.1.2. database language --
  clarion   = { inherit = 'dbl', desc = 'Clarion', masks = {'%.cl[aw]$'}, },
  clipper   = { inherit = 'dbl', desc = 'Clipper', masks = {'%.ch$','%.prg$'}, -- prg
                firstline = {lines.s_inc, lines.s_def, lines.s_if}, }, -- conflict -^
  foxpro    = { inherit = 'dbl', desc = 'FoxPro', masks = {'%.prg$','%.[sm]pr$'}, },
  paradox   = { inherit = 'dbl', desc = 'Paradox', masks = {'%.sc$'}, },
  sql       = { inherit = 'dbl', desc = 'SQL', masks = {'%.sql$'}, }, -- SQL, PL/SQL, MySQL
              -- SQL package, specification, type:
    sqluf   = { inherit = 'sql', desc = 'SQL-used files',
                masks = {'%.pck$','%.spc$','%.tps$'},
                strongline = {'^create or replace'}, },
  sqlj      = { inherit = 'dbl', desc = 'SQLJ', masks = {'%.sqlj$'}, },
                  -- rare
  -- [[
  s1c       = { inherit = 'dbl', desc = '1C', group = 'rare', masks = {'%.1c$'}, },
  baan      = { inherit = 'dbl', desc = 'Baan 4GL', group = 'rare', masks = {'%.cln$'}, },
  rsmac     = { inherit = 'dbl', desc = 'R-Style macro', group = 'rare',
                masks = {'%.rsl$','%.mac$'}, },
  --]]
  -- [[
  sql_emb   = { inherit = 'sql', desc = 'EmbeddedSQL', group = 'rare', },
  sql_c     = { inherit = 'sql_emb', desc = 'EmbeddedSQL for C', masks = {'%.sc$'}, },
  sql_cpp   = { inherit = 'sql_emb', desc = 'EmbeddedSQL for C++', masks = {'%.scpp$'}, },
  sql_cbl   = { inherit = 'sql_emb', desc = 'EmbeddedSQL for Cobol', masks = {'%.sco$'}, },
  --]]
              -- 1.3.1.-. .NET support language
  dotnet    = { inherit = 'main', desc = '.NET language', },
  cs        = { inherit = 'dotnet', desc = 'C#', masks = {'%.cs$'}, },
  js_net    = { inherit = 'dotnet', desc = 'JS.NET', masks = {'%.js$'}, },
  vb_net    = { inherit = 'dotnet', desc = 'VB.NET', masks = {'%.vb$'}, },

              -- 1.3.1.3. network language
  erb       = { inherit = 'net', desc = 'ERB - Rails HTML',
                masks = {'%.erb$','%.r?html$','html%.erb$'}, },
  php       = { inherit = 'net', desc = 'PHP',
                masks = {'%.php%d?$','%.[pt]html$'},
                strongline = {'^#%s-%S*php'}, },
  php_inc   = { inherit = 'php', masks = {'%.inc$'}, firstline = {'^<%?php'}, },

              -- 1.3.1.3.-. network script
  netscript = { inherit = 'net', desc = 'Network script', group = 'script', },
  ascript   = { inherit = 'netscript', desc = 'ActionScript', masks = {'%.as$'}, },
  coldfusion= { inherit = 'netscript', desc = 'ColdFusion', masks = {'%.cf[mc]$'}, },
  jscript   = { inherit = 'netscript', desc = 'JavaScript', masks = {'%.js$','%.mocha$'}, },
  vbscript  = { inherit = 'netscript', desc = 'VBScript', masks = {'%.vbs$'}, },

              -- 1.3.1.3.-. server pages
  asp       = { inherit = 'net', desc = 'Active Server Pages',
                masks = {masks.asp_as,masks.asp_ht}, },
  asp_vbs   = { inherit = 'asp', desc = 'ASP: VBScript',
                masks = msets.asp, firstline = {lines.lang..'vbscript', '<%%'}, },
  asp_js    = { inherit = 'asp', desc = 'ASP: JavaScript',
                masks = msets.asp,
                firstline = {lines.lang..'jscript',lines.lang..'javascript'}, },
  asp_ps    = { inherit = 'asp', desc = 'ASP: PerlScript',
                masks = msets.asp, firstline = {lines.lang..'perlscript'}, },
  adp       = { inherit = 'net', desc = 'AOLserver Dynamic Pages',
                masks = {'%.adp$'}, firstline = {lines.lang..'tcltk', '<%%'}, },
  jsp       = { inherit = 'net', desc = 'Java Server Pages',
                masks = {'%.jspf?$'}, },

          -- 1.3.2. Script language --
  --acapella= { inherit = 'script', desc = 'Acapella', -- It is required firstline!
  --            masks = {'%.script$','%.proc$','%.param$','%.parameter$'}, },
  avisynth  = { inherit = 'script', desc = 'AviSynth', masks = {'%.avsi?$'}, },
  farmacro  = { inherit = 'script', desc = 'FAR macros', masks = {'%.macro$'}, },
  farmail   = { inherit = 'script', desc = 'FARMail Script', masks = {'%.fms$'}, },
  tcl_tk    = { inherit = 'script', desc = 'Tcl/Tk', masks = {'%.tcl$','%.tk$'},
               strongline = {'^#!%s-%S*tcl','^#!%s-%S*wish'}, },
                  -- Lua:
  lua       = { inherit = 'script', desc = 'Lua', masks = {'%.lua$','%.wlua$'},
                strongline = {'^#!%s-%S*lua'}, firstline = {lines.lua_rem}, },
  lua_inc   = { inherit = 'lua', desc = 'Lua include',
                masks = {'%.script$'}, firstline = {lines.lua_rem}, },
  lua_dat   = { inherit = 'lua', desc = 'Lua data', group = 'config',
                masks = {'%.cfg$','history%.data$'}, firstline = {'^do local'}, },

              -- 1.3.2.1. batch/shell --
  batch     = { inherit = 'shell', desc = 'Batch', group = 'script',
                masks = {'%.cmd$','%.bat$','%.nt$','%.btm$','%.sys$'}, },
  sh        = { inherit = 'shell', desc = 'Shell', group = 'script',
                masks = {'%.sh$','^pkgbuild$'}, strongline = {'^#!%s-%S*sh'}, },
  csh       = { inherit = 'shell', desc = 'CSH script', group = 'script',
                masks = {'%.csh$'}, strongline = {'^#!%s-%S*csh'}, },
  bash      = { inherit = 'shell', desc = 'BASH script', group = 'script',
                masks = {'%.bash$'}, strongline = {'^#!%s-%S*bash'}, },
  fish      = { inherit = 'shell', desc = 'FISH script', group = 'script',
                masks = {'%.fish$'}, strongline = {'^#!%s-%S*fish'}, },
  apache    = { inherit = 'shell', desc = 'Apache httpd.conf', group = 'script',
                masks = {'httpd%.conf$','srm%.conf$','access%.conf$',
                         '%.htaccess$','apache%.conf$'}, },
                  -- rare
  --[[
  shell_r   = { inherit = 'shell', desc = 'Batch/Shell rare', group = 'rare', },
  dcl       = { inherit = 'shell_r', desc = 'HP OpenVMS DCL', masks = {'%.com$'}, },
  jcl       = { inherit = 'shell_r', desc = 'JCL',
                masks = {'%.jcl$'}, firstline = {'^//'}, },
  kixtart   = { inherit = 'shell_r', desc = 'Kixtart',
                masks = {'%.kix$','%.kixkix$'}, },
  rexx      = { inherit = 'shell_r', desc = 'REXX',
                masks = {'%.rexx?$','%.cmd$'},
                firstline = {'REM/%*','^# regina','^/%*%s-REXX%s-%*/'}, },
  urq       = { inherit = 'shell_r', desc = 'URQ', masks = {'%.qst$'}, }, -- unknown
  --]]
              -- 1.3.2.-. makefile
  makefile  = { inherit = 'script', desc = 'MakeFile script', },
  make      = { inherit = 'makefile', desc = 'MakeFile',
                masks = {'gnumakefile','^makefile','%.make?$','%.gmk$'}, },
  make_ms   = { inherit = 'makefile', desc = 'MakeFile: MS DS',
                masks = {'%.ds[pw]$'}, -- .. project/workspace
                firstline = {'Microsoft Developer Studio'}, },
  make_bor  = { inherit = 'makefile', desc = 'MakeFile: Borland',
                masks = {'%.bp[krg]$'}, }, -- .. project/package/group
  make_ap   = { inherit = 'makefile', desc = 'MakeFile: AirPlay SDK',
                masks = {'%.mk[bf]$'}, }, -- .. project/package/group
  make_sc   = { inherit = 'makefile', desc = 'SCons tool', group = 'script',
                masks = {'sconstruct$','sconscript$'}, }, -- Software Construction tool
                  -- rare
  autoit    = { inherit = 'script', desc = 'AutoIt', masks = {'%.aut$'}, }, -- 2.x
  ahk       = { inherit = 'script', desc = 'AutoHotkey',
                masks = {'%.ahk$'}, firstline = {'^;'}, },
  awk       = { inherit = 'script', desc = 'AWK',
                masks = {'%.awk$'}, strongline = {'^#%s-%S*gawk'}, },
  --[[
  asn1ecn   = { inherit = 'script', desc = 'ASN.1 / ECN',
                masks = {'%.asn1?$','%.ecn$','%.e[dl]m$','%.mib$','%-mib$'}, },
  lotusscript = { inherit = 'codscript', desc = 'LotusScript', group = 'vbscript',
                  masks = {'%.lss$'}, },
  pvwave    = { inherit = 'script', desc = 'PV-Wave', masks = {'%.pvw$'}, },
  renderman = { inherit = 'script', desc = 'Renderman', },
  rm_rib    = { inherit = 'renderman', desc = 'Renderman RIB', masks = {'%.rib$'}, },
  rm_shl    = { inherit = 'renderman', desc = 'Renderman Shading Language',
                masks = {'%.sli?$','%.slim$','%.str$','%.stree$'}, },
  s3dmax    = { inherit = 'script', desc = '3D Max script',
                masks = {'%.mel$','%.ms$'}, },
  sflex     = { inherit = 'script', desc = 'FlexScript', -- conflict with flex
                masks = {'%.src$','%.in[ct]$'},
                firstline = {'%*%*%*%*%*%*%*%*%*%*'}, },
  --]]
              -- 1.3.2.-. install script
  install   = { inherit = 'main', desc = 'Install script', group = 'script', },
  inst_is   = { inherit = 'install', desc = 'InstallShield script', masks = {'%.rul$'}, },
  inst_iss  = { inherit = 'install', desc = 'InnoSetup script', masks = {'%.iss$'}, },
  inst_nsi  = { inherit = 'install', desc = 'Nullsoft script', masks = {'%.ns[ih]$'}, },
  inst_rar  = { inherit = 'install', desc = 'RAR script', masks = {'%.s$'}, },

  -- 2. packed

      -- 2.1. exec --
  bin       = { inherit = 'exec', desc = 'Binary code',
                masks = {'%.exe$','%.com$',
                         '%.so$','%.dll$','%.lib$', '^io%.sys$'}, },
  bin_lua   = { inherit = 'exec', desc = 'Lua bin code', group = 'lua',
                masks = {'%.luc$'}, },

      -- 2.2. store --

          -- 2.2.1. arch --
  arc       = { inherit = 'arch', desc = 'Archive',
                masks = {'%.7z$','%.7zip$','%.zip$','%.t?gz$','%.bz2$',
                         '%.[jrt]ar$','%.[ra]%d%d$',
                         '%.arj$','%.lzh$','%.ha$',
                         '%.wsz$','%.ace$','%.j$','%.z$'}, },

  setup     = { inherit = 'arch', desc = 'Setup file', masks = {'%.msi$'}, },

          -- 2.2.2. disk --
  disk_hd   = { inherit = 'disk', desc = 'Hard disk image',
                masks = {'%.image$','%.vhd$'}, },
  disk_cd   = { inherit = 'disk', desc = 'Compact disk image',
                masks = {'%.iso$','%.mdf$','%.nrg$','%.[fv]cd$'}, },

      -- 2.3. media

          -- 2.3.1. image --
  ico       = { inherit = 'image', desc = 'Icon image',   masks = {'%.icon?$'}, },
  cursor    = { inherit = 'image', desc = 'Cursor image', masks = {'%.ani$','%.cur$'}, },
  bitmap    = { inherit = 'image', desc = 'Bitmap graphics',
                masks = {'%.bmp$','%.dib$','%.[dp]cx$'}, },
  vector    = { inherit = 'image', desc = 'Vector graphics', masks = {'%.[ew]mf$'}, },
  wavelet   = { inherit = 'image', desc = 'Wavelet graphics', masks = {'%.wvl$'}, },
  graphic   = { inherit = 'image', desc = 'Picture graphics',
                masks = {'%.png$','%.tga$','%.targa$','%.[grt]iff?$','%.gif87$',
                         '%.jp[2eg]$','%.jpeg$','%.j[fi]f$','%.jfif?$','%.p[bnp]m$',
                         '%.iff$','%.kd[ck]$','%.psd$'}, },
              -- rare
  --[[
  bitmap_r  = { inherit = 'image', desc = 'Bitmap graphics', group = 'rare',
                masks = {'%.bmp24$','%.b[&_]?w$','%.ic[bc]$','%.im[18]?$',
                         '%.im24$','%.im32$','%.pcds?$','%.rg$','%.rgba?$'}, },
  graphic_r = { inherit = 'image', desc = 'Picture graphics', group = 'rare',
                masks = {'%.face?$','%.fpx$','%.g[34]$','%.i?lbm$','%.jpc$',
                         '%.mag$','%.pct$','%.pgm$','%.pix$','%.pixar$',
                         '%.pseg?$','%.rast?$','%.rl[48abce]$','%.sgi$',
                         '%.vic$','%.vicar$'}, },
  --picture   = { inherit = 'image', desc = 'Picture image',
                  masks = {'%.pmb$'}, },
  --]]
          -- 2.3.2. audio --
  wave      = { inherit = 'audio', desc = 'Wave audio',
                masks = {'%.wav$','%.cda$','%.[ap]cm$','%.adpcm$',
                         '%.aif[cf]?$','%.dac$','%.flac$','%.raw$'}, },
  sound     = { inherit = 'audio', desc = 'Sound audio',
                masks = {'%.mp[23]$','%.ogg$','%.wma$','%.swa$'}, },
  music     = { inherit = 'audio', desc = 'Music audio',
                masks = {'%.[acd]mf$','%.mus$','%.vqf$'}, },
  midi      = { inherit = 'music', desc = 'MIDI',
                masks = {'%.midi?$','%.kar$','%.hm[ip]$','%.[rx]mi$','%.sng$',
                         '%.id[df]$','%.imf$','%.mff$','%.mss$','%.sds$','%.xwf$'}, },
  audible   = { inherit = 'audio', desc = 'Audible audio', masks = {'%.aa$'}, },
              -- rare
  --[[
  wave_r    = { inherit = 'audio', desc = 'Wave audio', group = 'rare',
                masks = {'%.au$','%.[au]l$','%.[au]law$','%.f32','%.f64',
                         '%.psion$','%.s[bd]$','%.sw$','%.ub$','%.ud?w$'}, },
  sound_r   = { inherit = 'audio', desc = 'Sound audio', group = 'rare',
                masks = {'%.g72[136]?','%.inrs','%.lwz','%.sll','%.song?$'}, },
  music_r   = { inherit = 'audio', desc = 'Music audio',
                masks = {'%.4md$','%.66[89]$','%.[68]cm$','%.avr$','%.bmw$',
                         '%.dig$','%.dls$','%.ds[fms]$','%.dwd$','%.esps$',
                         '%.fnk$','%.fssd','%.gdm$','%.hsc$',
                         '%.jms$','%.lqt$','%.m[fj]f$','%.mus10$','%.nst$',
                         '%.o[ck]t$','%.psm$','%.r[ft]m$','%.svq$','%.uwf$'}, },
  --]]
  --[[
  farallon  = { inherit = 'sound', desc = 'Farallon\'s MacRecorder',
                masks = {'%.m11','%.m22','%.m7'}, },
  farandole = { inherit = 'music', desc = 'Farandole Module',
                masks = {'%.f[23a]r$','%.fsm$'}, },
  --]]
          -- 2.3.3. video --
  movie     = { inherit = 'video', desc = 'Movie video',
                masks = {'%.mp[4g]?$','%.mpeg?$','%.wmv$',
                         '%.cdv$','%.vob$','%.vqa$',
                         '%.bik$','%.smk$'}, },
  flash     = { inherit = 'video', desc = 'Flash media',
                masks = {'%.swf$','%.fl[av]$'}, },
              -- rare
  --[[
  movie_r   = { inherit = 'video', desc = 'Movie video', group = 'rare',
                masks = {'%.dv$','%.fmv$','%.mpv2$'}, },
  --]]
          -- 2.3.-. other --
  streaming = { inherit = 'media', desc = 'Streaming media',
                masks = {'%.as[fx]$','%.ram$','%.vivo?$'}, },
  s_audio   = { inherit = 'audio', desc = 'Audio stream', group = 'stream',
                masks = {'%.m[123]a$','%.ra$','%.mp[123a]$','%.gsm$'}, },
  s_video   = { inherit = 'video', desc = 'Video stream', group = 'stream',
                masks = {'%.m[123]v$','%.rv$'}, },
  s_media   = { inherit = 'media', desc = 'Media stream', group = 'stream',
                masks = {'%.m[1]s$'}, },

  -- 3. mixed
  example   = { inherit = 'mixed', masks = {'%.example$'}, }, -- unknown
  xml_zip   = { inherit = 'mixed', desc = 'Zipped XML document', },

      -- 3.1. doc --
  mso       = { inherit = 'doc', desc = 'MS Office document',
                masks = {'%.do[ct]$','%.xl[sta]$','%.pp[tsa]$','%.pot$','%.vs[dsa]$',
                         '%.mcw$','%.pwd$','%.psw$','%.wri$'}, },
  mso_xml   = { inherit = 'doc', desc = 'MS Office XML document', group = 'xml_zip',
                masks = {'%.do[ct][xm]$','%.xl[sta][xm]$',
                         '%.pp[tsa][xm]$','%.v[dsa]x$'}, },
  ooo       = { inherit = 'doc', desc = 'OpenOffice.org document',
                masks = {'%.sx[wcidgm]$','%.st[wcid]$'}, },
  odf       = { inherit = 'doc', desc = 'Open document',
                masks = {'%.od[tspgfbm]$','%.ot[tspgh]$'}, },
  xps       = { inherit = 'doc', desc = 'XML Paper Specification',
                group = 'xml_zip',
                masks = {'%.xps$'}, },
  lotus     = { inherit = 'doc', desc = 'Lotus 123 document',
                masks = {'%.wj[23]$','%.wk[34]$','%.123$'}, },
  dvi       = { inherit = 'doc', desc = 'TeX DVI document',
                masks = {'%.x?dvi$','%.xdvik$'}, },
  pdf       = { inherit = 'doc', desc = 'Adobe PDF document',
                masks = {'%.e?pdf$'}, },
              -- Composed help:
  hlp       = { inherit = 'doc', desc = 'Composed help', group = 'arch', },
  hlp_rtf   = { inherit = 'hlp', desc = 'RTF help', masks = {'%.hlp$'}, },
  hlp_chm   = { inherit = 'hlp', desc = 'HTML help', masks = {'%.chm$'}, },

      -- 3.2. font --
  fontmetric  = { inherit = 'font', desc = 'Font metric', },
  fm_tex    = { inherit = 'fontmetric', desc = 'TeX font metric', masks = {'%.tfm$'}, },
  fm_ps     = { inherit = 'fontmetric', desc = 'PS font metric', masks = {'%.[ap]fm$'}, },

      -- 3.3. others --
  link      = { inherit = 'mixed', desc = 'Link', },
  lnk       = { inherit = 'link', desc = 'Link file', masks = {'%.lnk$'}, },
  -- end
} --- types

---------------------------------------- main
setmetatable(types, { __index = abstract_types })

--------------------------------------------------------------------------------
return types
--------------------------------------------------------------------------------
