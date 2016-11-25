l3c = require 'go'
uv = require 'luv'

local function sleep(n)
   local t = uv.new_timer()
   t:start(n, 0, l3c.async_handler(t))
   coroutine.yield('async', t)
end

local function signal(sig)
   local h = uv.new_signal()
   uv.signal_start(h, sig, l3c.async_handler(h))
   coroutine.yield('async', h)
end


local function tmr(ch)
   while true do
      print 'a'
      signal 'sighup'
      sleep (1000)
      print 'b'
      l3c.send(ch, 1)
   end
end

local function uvce()
   ch = l3c.chan()
   l3c.go (tmr, ch)
   while true do
      l3c.recv(ch)
      print  'sec'
   end
end

l3c.run(uvce)


local function to(ch1, ch2)
   while true do
      local x = l3c.recv(ch1)
      l3c.send(ch2, x + 1)
   end
end

local function from()
   local ch1 = l3c.chan()
   local ch2 = l3c.chan()

   local ch3 = l3c.chan()
   local ch4 = l3c.chan()

   l3c.go (to, ch1, ch2)
   l3c.go (to, ch3, ch4)

   local x = 0
   l3c.send(ch1, x)
   while x < 20 do
      x = l3c.recv(ch2)
      print (x)
      l3c.send(ch3, x)
      x = l3c.recv(ch4)
      print (x)
      l3c.send(ch1, x)
   end
end

--l3c.run (from)
