local minidoc = require("mini.doc")

if _G.MiniDoc == nil then
  minidoc.setup()
end

MiniDoc.generate({ "lua/presenting.lua" }, "doc/presenting.txt", {})
