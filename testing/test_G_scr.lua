local _G = _G

far.Show(
  rawget(_G, "global_var"),
  --_G.global_var,
  rawget(_G, "other_var"),
  --_G.other_var,
  rawget(_G, "undecl_var")
)
