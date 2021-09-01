-- Sysprof is implemented for x86 and x64 architectures only.
require("utils").skipcond(
  jit.arch ~= "x86" and jit.arch ~= "x64" or jit.os ~= "Linux",
  jit.arch.." architecture or "..jit.os..
  " OS is NIY for sysprof"
)

local tap = require("tap")

local test = tap.test("misc-sysprof-lapi")
test:plan(14)

jit.off()
jit.flush()

local bufread = require("utils.bufread")
local symtab = require("utils.symtab")
local sysprof = require("sysprof.parse")

local TMP_BINFILE = arg[0]:gsub(".+/([^/]+)%.test%.lua$", "%.%1.sysprofdata.tmp.bin")
local BAD_PATH = arg[0]:gsub(".+/([^/]+)%.test%.lua$", "%1/sysprofdata.tmp.bin")

local function payload()
  local function fib(n)
    if n <= 1 then
      return n
    end
    return fib(n - 1) + fib(n - 2)
  end
  return fib(32)
end

local function generate_output(opts)
  local res, err = misc.sysprof.start(opts)
  assert(res, err)

  payload()

  res,err = misc.sysprof.stop()
  assert(res, err)
end

local function check_mode(mode, interval)
  local res = pcall(
    generate_output,
    { mode = mode, interval = interval, path = TMP_BINFILE }
  )

  if not res then
    test:fail(mode .. ' mode with interval ' .. interval)
    os.remove(TMP_BINFILE)
  end

  local reader = bufread.new(TMP_BINFILE)
  local symbols = symtab.parse(reader)
  sysprof.parse(reader, symbols)
end

-- GENERAL

-- Wrong profiling mode.
local res, err, errno = misc.sysprof.start{ mode = "A" }
test:ok(res == nil and err:match("profiler misuse"))
test:ok(type(errno) == "number")

-- Already running.
res, err = misc.sysprof.start{ mode = "D" }
assert(res, err)

res, err, errno = misc.sysprof.start{ mode = "D" }
test:ok(res == nil and err:match("profiler misuse"))
test:ok(type(errno) == "number")

res, err = misc.sysprof.stop()
assert(res, err)

-- Not running.
res, err, errno = misc.sysprof.stop()
test:ok(res == nil and err)
test:ok(type(errno) == "number")

-- Bad path.
res, err, errno = misc.sysprof.start({ mode = "C", path = BAD_PATH })
test:ok(res == nil and err:match("No such file or directory"))
test:ok(type(errno) == "number")

-- Bad interval.
res, err, errno = misc.sysprof.start{ mode = "C", interval = -1 }
test:ok(res == nil and err:match("profiler misuse"))
test:ok(type(errno) == "number")

-- DEFAULT MODE

if not pcall(generate_output, { mode = "D", interval = 11 }) then
  test:fail('`default` mode with interval 11')
end

local report = misc.sysprof.report()

test:ok(report.samples > 0)
test:ok(report.vmstate.LFUNC > 0)
test:ok(report.vmstate.TRACE == 0)

-- With very big interval.
if not pcall(generate_output, { mode = "D", interval = 1000 }) then
  test:fail('`default` mode with interval 1000')
end

report = misc.sysprof.report()
test:ok(report.samples == 0)

-- LEAF MODE
check_mode("L", 11)

-- CALL MODE
check_mode("C", 11)

os.remove(TMP_BINFILE)

jit.on()
os.exit(test:check() and 0 or 1)
