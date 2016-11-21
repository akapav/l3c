----- utils -----
local q = require 'queue'

local function log (fmt, ...)
   print (string.format(fmt, ...))
end

----- async call -----
local gfd = 0
local function wait()
   gfd = gfd + 1
   log("next fd = %d", gfd)
   coroutine.yield('async', gfd)
end

----- channels -----
local chid = 0
local function chan(size)
   chid = chid + 1
   local ch = { id = chid; q = q.fixed_queue_new(size) }
   return ch
end

local recv_pull
local function send(ch, val)
   if ch.q:is_full() then
      coroutine.yield('schan', ch.id)
   end
   recv_pull(ch.id)
   ch.q:enqueue(val)
end

local send_pull
local function recv(ch)
   if ch.q:is_empty() then
      coroutine.yield('rchan', ch.id)
   end
   send_pull(ch.id)
   return ch.q:dequeue()
end

----- tasks -----
local function thunk(f, ...)
   local args = { ... }
   return function () return f(unpack(args)) end
end

local pending_tasks = q.queue_new()

local function go(task, ...)
   local f = thunk(task, ...)
   pending_tasks:enqueue(coroutine.create(f))
end

local async_tasks = {}

local function add_wait_queue(wq, chid, task)
   if not wq[chid] then
      wq[chid] = q.queue_new()
   end
   wq[chid]:enqueue(task)
end

local function pull_wait_queue(wq, chid)
   if not wq[chid]        then return end
   if wq[chid]:is_empty() then return end

   pending_tasks:enqueue(wq[chid]:dequeue())
end

local send_wq = {}

function send_wait(chid, task)
   add_wait_queue(send_wq, chid, task)
end

send_pull = function (chid) pull_wait_queue(send_wq, chid) end

local recv_wq = {}
function recv_wait(chid, task)
   add_wait_queue(recv_wq, chid, task)
end

recv_pull = function (chid) pull_wait_queue(recv_wq, chid) end

local function resume(task)
   if not task then return end
   
   local ok, type, key = coroutine.resume(task)
   if not ok then return end -- task throwed an exception
   if coroutine.status(task) == 'dead' then return end

   if     type == 'async' then async_tasks[key] = task
   elseif type == 'schan' then send_wait(key, task)
   elseif type == 'rchan' then recv_wait(key, task)
   end
end

local function run_pending()
   while not pending_tasks:is_empty() do
      resume(pending_tasks:dequeue())
   end
end

local function flush_chans()
   repeat
      run_pending()
   until pending_tasks:is_empty()
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
      flush_chans()
      log ("async wait started")
      async_wait()
      loop()
   end
   
   go(f)
   loop()
end

----- test -----
local function f2(x, y)
   log ("f2: %d %d", x, y)
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

--run(main)


----- test2 -----

local function to(ch1, ch2)
   while true do
      local x = recv(ch1)
      send(ch2, x + 1)
   end
end

local function from()
   local ch1 = chan()
   local ch2 = chan()

   local ch3 = chan()
   local ch4 = chan()
   
   go (to, ch1, ch2)
   go (to, ch3, ch4)

   local x = 0
   send(ch1, x)
   while x < 20 do
      x = recv(ch2)
      print (x)
      send(ch3, x)
      x = recv(ch4)
      print (x)
      send(ch1, x)
   end
end

--run(from)

----- test3 -----

local function r(ch, str)
   while true do
      log ("%s: %d", str, recv(ch))
   end
end

local function w()
   local ch = chan()
   go (r, ch, "t1")
   go (r, ch, "t2")
   while true do
      for i = 1, 10 do
	 send(ch, i)
      end
      wait()
   end
end

run(w)
