l3c = require 'go'
uv = require 'luv'

local function log (fmt, ...)
   print (string.format(fmt, ...))
end

local run = l3c.run(function () uv.run "once" end)

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

local function server_create(addr, port)
   local ch = l3c.chan()
   local srv = uv.new_tcp()
   uv.tcp_bind(srv, addr, port)
   local cc =  function (err)
      if err then return end
      local cli = uv.new_tcp()
      uv.accept(srv, cli)
      ch:send(cli)
   end
   uv.listen(srv, 128, cc)
   return ch
end

local function read(cli)
   local err   = nil
   local chunk = nil
   uv.read_start(cli, function (err_, chunk_)
		    err   = err_
		    chunk = chunk_
		    l3c.async_handler(cli)()
   end)
   coroutine.yield('async', cli)
   return err, chunk
end

local function reader(cli, n)
   while true do
      local err, msg = read(cli)
      if err then log ("#%d: <<error>>", n)
      else        log ("#%d: %s", n, msg)
      end
   end
end

local function main()
   local sch = server_create("127.0.0.1", 8110)
   local n = 0
   while true do
      n = n + 1
      local cli = sch:recv()
      l3c.go (reader, cli, n)
   end
end

run(main)

--server(33)
