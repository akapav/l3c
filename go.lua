local gfd = 0
local function wait()
   gfd = gfd + 1
   print(gfd)
   coroutine.yield('async', gfd)
end

------

local function thunk(f, ...)
   local args = { ... }
   return function () return f(unpack(args)) end
end

local pending_tasks = {}

local function go(task, ...)
   local f = thunk(task, ...)
   table.insert(pending_tasks, coroutine.create(f))
end

local async_tasks = {}
local function resume(task)
   local ok, type, key = coroutine.resume(task)
   if not ok then return end -- task throwed an exception
   if coroutine.status(task) == 'dead' then return end
   if type == 'async' then async_tasks[key] = task end
end

local function run_pending()
   for _, task in ipairs(pending_tasks) do
      resume(task)
   end
   pending_tasks = {}
end

local function async_wait()
   local fd = io.read("*n") --select
   local task = async_tasks[fd]
   if task then
      async_tasks[fd] = nil
      resume(task)
   end
end

local function run(f)
   local function loop()
      run_pending()
      async_wait()
      loop()
   end
   
   go(f)
   loop()
end

------ test -----
local function f2(x, y)
   print(string.format("f2: %d %d", x, y))
   while true do
      print "f2: alo prije"
      wait()
      print "f2: alo posli"
   end
end

local function f3()
   --while true do
      print "f3: alo prije"
      wait()
      print "f3: alo posli"
   --end
end

local function main()
   go(f2, 100, 200)
   go(f3)
   while true do
      print "alo prije"
      wait()
      print "alo posli"
   end
end

run(main)

