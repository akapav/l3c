local list = {}

local tbl = require 'table.new'

local function cons_alloc(h, t)
   local cell = tbl(2, 0)
   cell[1] = h
   cell[2] = t
   return cell
end

function list.new(...)
   local args = { ... }
   local cons  = nil
   for i = #args, 1, -1 do
      cons = cons_alloc(args[i], cons)
   end
   return cons
end

function list.first(cell)
   assert(cell, 'empty cell')
   return cell[1]
end

function list.first_set(cell, h)
   assert(cell, 'empty cell')
   cell[1] = h
   return cell
end

function list.rest(cell)
   assert(cell, 'empty cell')
   return cell[2]
end

function list.rest_set(cell, t)
   assert(cell, 'empty cell')
   cell[2] = t
   return cell
end

return list
