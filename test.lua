l3c = require 'go'

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

l3c.run(nil) (from)
