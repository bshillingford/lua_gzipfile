local ffi = require 'ffi'

-- C file IO functions, will be placed in ffi.C namespace
-- Note: some pointer types changed for convenience
ffi.cdef[[
typedef void FILE;
typedef struct {
  void *read;
  void *write;
  void *seek;
  void *close;
} cookie_io_functions_t;
FILE *fopencookie(void *cookie, const char *mode,
  cookie_io_functions_t io_funcs);
FILE* funopen(
  const void *cookie,
  int (*readfn)(void *, char *, int),
  int (*writefn)(void *, const char *, int),
  void* seekfn,
  int (*closefn)(void *));
FILE* fopen(const char * path, const char * mode);
int fscanf(FILE* stream, const char* fmt, ...);
size_t fread(void* ptr, size_t size, size_t count, FILE* stream);
size_t fwrite(const void* ptr, size_t size, size_t count, FILE* stream);
int fgetc(FILE* stream);
int ungetc(int c, FILE* stream);
int fflush(FILE* stream);
long int ftell(FILE* stream);
int fseek(FILE* stream, long int offset, int origin);
int fclose(FILE* stream);
]]
local C = ffi.load('c')

-- Relevant zlib functions, this namespace is returned
ffi.cdef[[
typedef void* gzFile;
gzFile gzopen(const char *, const char *);
int gzread(gzFile file, void* buf, unsigned len);
int gzwrite(gzFile file, const void* buf, unsigned len);
int gzclose(gzFile file);
long gzseek(gzFile, long, int);
]]
local zlib = ffi.load(ffi.os == "Windows" and "zlib1" or "z")

-- zlib fake "fopen" using funopen
local helpers = {}
function helpers.gzfopen(path, mode)
  local zfp = ffi.new('gzFile[1]')
  local zfp = zlib.gzopen(path, mode)
  if not zfp then
    error('zlib: gzopen returned '..tostring(zfp))
  end
  if ffi.os == 'Linux' then
    local cookiefunc = ffi.new('cookie_io_functions_t')
    cookiefunc.read = zlib.gzread
    cookiefunc.write = zlib.gzwrite
    cookiefunc.seek = zlib.gzseek
    cookiefunc.close = zlib.gzclose
    return C.fopencookie(zfp, mode, cookiefunc)
  else
    return C.funopen(zfp,
               zlib.gzread,
               zlib.gzwrite,
               zlib.gzseek,
               zlib.gzclose)
  end
end
helpers.SEEK_SET = 0
helpers.SEEK_CUR = 1
helpers.SEEK_END = 2

return zlib, C, helpers
