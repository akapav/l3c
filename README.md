L3C - Lua concurrency using channels and coroutines
---------------------------------------------------

L3C is Lua library for concurrent programming. It's two basic
concurrency primitives are lightweight cooperative threads and
communication channels.

The project is under heavy development.

Example:
~~~
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

run (from)
~~~
