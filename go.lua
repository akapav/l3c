----- utils -----
local q = require 'queue'

local function log (fmt, ...)
   print (string.format(fmt, ...))
end

local function thunk(f, ...)
   local args = { ... }
   return function () return f(unpack(args)) end
end

----- channels -----
local recv_pull
local function send(ch, val)
   while ch.q:is_full() do
      coroutine.yield('schan', ch.id)
   end
   recv_pull(ch.id)
   ch.q:enqueue(val)
end

local send_pull
local function recv(ch)
   while ch.q:is_empty() do
      coroutine.yield('rchan', ch.id)
   end
   send_pull(ch.id)
   return ch.q:dequeue()
end

local chid = 0
local chan_mt = { __index = { send = send, recv = recv }}
local function chan(size)
   chid = chid + 1
   local ch = { id = chid; q = q.fixed_queue_new(size) }
   setmetatable(ch, chan_mt)
   return ch
end

local function select (s)
   local chids = {}
   while true do
      for i = 1, #s do
	 local ch = s[i][1]
	 if not ch.q:is_empty() then
	    s[i][2](ch.q:dequeue())
	    return
	 end
	 chids[#chids + 1] = ch.id
      end
      coroutine.yield('selec', chids)
   end
end

----- tasks -----
local pending_tasks = q.queue_new()

local async_tasks = {}
local function async_handler(handle)
   return function()
      local task = async_tasks[handle]
      if not task then return end
      async_tasks[handle] = nil
      pending_tasks:enqueue(task) 
   end
end

local function add_wait_queue(wq, chid, task)
   if not wq[chid] then
      wq[chid] = q.queue_new()
   end
   wq[chid]:enqueue(task)
end

local function pull_wait_queue(wq, chid)
   if not wq[chid]        then return end
   if wq[chid]:is_empty() then return end

   local qtask = wq[chid]:dequeue()
   if     type(qtask) == 'thread' then pending_tasks:enqueue(qtask)
   elseif qtask.consumed          then pull_wait_queue(wq, chid)
   else
      qtask.consumed = true
      pending_tasks:enqueue(qtask.task)
   end
end

local send_wq = {}
function send_wait(chid, task) add_wait_queue(send_wq, chid, task) end
send_pull = function (chid) pull_wait_queue(send_wq, chid) end


local recv_wq = {}
function recv_wait(chid, task) add_wait_queue(recv_wq, chid, task) end
recv_pull = function (chid) pull_wait_queue(recv_wq, chid) end

local function select_wait (chids, task)
   local stask = { task = task, consumed = false }
   for i = 1, #chids do  recv_wait(chids[i], stask)  end
end

local function resume(task)
   --if not task then return end
   
   local ok, type, key = coroutine.resume(task)
   if not ok then print "kita"; return end -- task throwed an exception
   if coroutine.status(task) == 'dead' then return end

   if     type == 'async' then async_tasks[key] = task
   elseif type == 'schan' then send_wait(key, task)
   elseif type == 'rchan' then recv_wait(key, task)
   elseif type == 'selec' then select_wait(key, task)
   end
end

local function flush_pending_tasks()
   while not pending_tasks:is_empty() do
      resume(pending_tasks:dequeue())
   end
end

local function go(task, ...)
   local f = thunk(task, ...)
   pending_tasks:enqueue(coroutine.create(f))
end

local function run(step)
   return function (f)
      go(f)
   
      while true do
	 flush_pending_tasks()
	 step()
      end
   end
end

----- iface -----
return {
   go  = go,
   run = run
   ;
   chan = chan,
   recv = recv,
   send = send,
   select = select
   ;
   async_handler = async_handler
}
