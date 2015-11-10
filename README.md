# gzfile
Conveniently (and with decent performance) read and write data from `gzip` 
files directly. Useful for text or very large files.

Implemented as an FFI wrapper for zlib, including wrappers for C `FILE` 
functions like `fscanf` and `fwrite`. More can be easily added.

Install:
```
luarocks install https://raw.githubusercontent.com/bshillingford/lua_gzipfile/master/gzfile-scm-1.rockspec
```

## Example:
Read 200 floats from a gzipped file directly into a torch tensor:
```lua
require 'torch'
local GZFile = require 'gzfile.GZFile'

local tensor = torch.FloatTensor(200)
local f = GZFile('floats.gz', 'rb')
f:readbuf(tensor:data(), 200*4)  -- sizeof(float)=4; read 200*4 bytes
f:close()
-- now do stuff with the tensor
```
Note: compressing floats can be useful for neural nets, since similar values at
similar orders of magnitude will often results in repeated byte patterns.

To access the underlying `FILE*` handle, use the `handle` property of `GZFile`.

## Functions implemented:

  * Constructor: `file = GZFile(filename, mode)`
    Opens the file for reading or writing using the given mode.
    See zlib gzopen() documentation for supported modes.
  * `:close()` Closes the file. Later operations will fail.
  * `:write(str)`
    Writes a lua string. Doesn't allocate memory, just casts using ffi.
    Calls fwrite and returns its ret val, i.e. number of bytes written.
  * `:read(nbytes)`
    Reads to a buffer then turns into a lua string.
    Allocates memory on each call, so slightly inefficient if you do many
    reads.
  * `:writebuf(ptr, nbytes)`
    Writes data from the given buffer to the file.
    Returns number of bytes written.
  * `:readbuf(ptr, nbytes)`
    Reads into the given location in memory.
    Returns number of bytes read.
  * `:flush()`
  * `:peek()`
  * `:tell()`
    Returns the position in the file using ftell.
  * `:seek(offset, origin)`
    Seek using fseek, relative to beginning of file.
    Note the argument order matches C's rather than Lua's io.
    Returns new position from ftell.
  * `:getc()`
  * `:scanf(fmt, typestring)`
    Calls fscanf, but only for reading a single field e.g. `%s`.
    Allocates memory automatically, this memory will be gc'd by lua.
    Typestring examples: `'float[1]'`, `'uint8_t[1]'`, `'char[16]'`.
