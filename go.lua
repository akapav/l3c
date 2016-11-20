local gfd = 0

local function wait()
   gfd = gfd + 1
   print(gfd)
   coroutine.yield(gfd)
end

local pending_tasks = {}

local tasks = {}

local function go(task)
   table.insert(pending_tasks, coroutine.create(task))
end

local function run_pending()
   for _, task in ipairs(pending_tasks) do
      local _, fd = coroutine.resume(task)
      print(fd)
      tasks[fd] = task
   end
   pending_tasks = {}
end

local function run(f)
   local function loop()
      run_pending()
      local fd = io.read("*n") --select
      local task = tasks[fd]
      if task then
	 tasks[fd] = nil
	 local _, fd = coroutine.resume(task)
	 local status = coroutine.status(task)
	 if status == 'suspended' then tasks[fd] = task end
      end
      loop()
   end
   
   go(f)
   loop()
end

------
local function f2()
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
   go(f2)
   go(f3)
   while true do
      print "alo prije"
      wait()
      print "alo posli"
   end
end

run(main)

