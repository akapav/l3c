--local p = require('lib/utils').prettyPrint
local uv = require('luv')

local function create_server(host, port, on_connection)

  local server = uv.new_tcp()
  --p(1, server)
  uv.tcp_bind(server, host, port)

  uv.listen(server, 128, function(err)
    assert(not err, err)
    local client = uv.new_tcp()
    uv.accept(server, client)
    on_connection(client)
  end)

  return server
end

local server = create_server("127.0.0.1", 8110, function (client)
				print 'kita'
  uv.read_start(client, function (err, chunk)
    assert(not err, err)

    if chunk then
      -- Echo anything heard
      uv.write(client, '...' .. chunk)
    else
      -- When the stream ends, close the socket
      uv.close(client)
    end
  end)
end)

uv.run()
-- Close any stray handles when done
uv.walk(uv.close)
uv.run()
uv.loop_close()
