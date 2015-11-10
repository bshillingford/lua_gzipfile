package = "gzfile"
version = "scm-1"

source = {
   url = "git://github.com/bshillingford/lua_gzipfile.git",
}

description = {
   summary = "GZip stream reader for Lua using FFI",
   detailed = [[
   ]],
   homepage = "https://github.com/bshillingford/lua_gzipfile",
   license = "BSD"
}

dependencies = {
   "lua >= 5.1",
}

build = {
   type = "builtin",
   modules = {
      ["gzfile.GZFile"] = "GZFile.lua",
      ["gzfile.utils"] = "utils.lua",
      ["gzfile.zlibffi"] = "zlibffi.lua",
   },
   install = {
      lua = {
      }
   }
}

