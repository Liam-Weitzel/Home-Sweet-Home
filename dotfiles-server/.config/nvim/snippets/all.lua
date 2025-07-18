-- all.lua
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
  s("all_test", {
    t("local "),
    i(1, "module"),
    t(" = require('"),
    i(2, "module"),
    t("')"),
  }),
}
