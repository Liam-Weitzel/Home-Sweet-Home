-- all.lua
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node

return {
  s("all_test", {
    t("local "),
    i(1, "module"),
    t(" = require('"),
    c(2, {
      t("module"),
      t("module.submodule"),
      t("another_module"),
    }),
    t("')"),
  }),
}
