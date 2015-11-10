local ffi = require 'ffi'
local zlib, C, helpers = paths.dofile('zlibffi.lua')
local utils = paths.dofile('utils.lua')

local GZFile = utils.class('GZFile')

local uint8_t = ffi.typeof('unsigned char')
local uint8_t_p = ffi.typeof('unsigned char*')
local void_p = ffi.typeof('void*')

--[[
Opens the file for reading or writing using the given mode.
See zlib gzopen() documentation for supported modes.
]]
function GZFile:_init(filename, mode)
  self.handle = helpers.gzfopen(filename, mode)
  assert(self.handle)
end

--[[
Closes the file. Later operations will fail.
]]
function GZFile:close()
  local ret = C.fclose(self.handle)
  self.handle = nil
  return ret
end

--[[
Writes a lua string. Doesn't allocate memory, just casts using ffi.
Calls fwrite and returns its ret val, i.e. number of bytes written.
]]
function GZFile:write(str)
  assert(self.handle)
  local buf = ffi.cast(void_p, str)
  return C.fwrite(buf, 1, #str, self.handle)
end
--[[
Reads to a buffer then turns into a lua string.
Allocates memory on each call, so slightly inefficient if you do many
reads.
]]
function GZFile:read(nbytes)
  assert(self.handle)
  local buf = ffi.new('uint8_t[?]', nbytes)
  local count = C.fread(buf, 1, nbytes, self.handle)
  return ffi.string(buf, count)
end

--[[
Writes data from the given buffer to the file.
Returns number of bytes written.
]]
function GZFile:writebuf(ptr, nbytes)
  assert(self.handle)
  return C.fwrite(ptr, 1, nbytes, self.handle)
end
--[[
Reads into the given location in memory.
Returns number of bytes read.
]]
function GZFile:readbuf(ptr, nbytes)
  assert(self.handle)
  return C.fread(ptr, 1, nbytes, self.handle)
end

function GZFile:flush()
  assert(self.handle)
  if C.fflush(self.handle) ~= 0 then
    return nil, 'fflush failed'
  end
  return true
end

function GZFile:peek()
  assert(self.handle)
  local c = C.fgetc(self.handle)
  C.ungetc(c, self.handle)
  return c
end

--[[
Returns the position in the file using ftell.
]]
function GZFile:tell()
  assert(self.handle)
  return C.ftell(self.handle)
end

--[[
Seek using fseek, relative to beginning of file.
Note the argument order matches C's rather than Lua's io.
Returns new position from ftell.
]]
function GZFile:seek(offset, origin)
  if origin == nil or origin == 'set' then
    origin = helpers.SEEK_SET
  elseif origin == 'end' then
    origin = helpers.SEEK_END
  elseif origin == 'cur' then
    origin = helpers.SEEK_CUR
  else
    error('invalid argument for 2nd arg, origin/whence. Expect int or cur/set/end.')
  end
  assert(self.handle)
  if C.fseek(offset, origin) ~= 0 then
    return nil, 'fseek returned an error'
  end
  return C.ftell(self.handle)
end

function GZFile:getc()
  assert(self.handle)
  return C.fgetc(self.handle)
end

--[[
Calls fscanf, but only for reading a single field e.g. %s.
Allocates memory automatically, this memory will be gc'd by lua.
Typestring examples: 'float[1]', 'uint8_t[1]', 'char[16]'.
]]
function GZFile:scanf(fmt, typestring)
  assert(self.handle)
  assert(typestring, 'must specify an ffi typestring')
  local buf = ffi.new(typestring)
  if C.fscanf(self.handle, fmt, buf) ~= 1 then
    return nil, 'fscanf did not read one field'
  end
  return buf
end

return GZFile
