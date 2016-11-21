
-- utils
local function mk_arr(n)
   local arr = {}
   for i = 0, n do table.insert(arr, 0) end
   return arr
end

local function inc_mod(n, m)
   return (n + 1) % m
end


local function log (fmt, ...)
   print (string.format(fmt, ...))
end

-- list
local function list(h, t)
   return { h_ = h, t_ = t }
end

local function first(cell)
   assert(cell, 'empty cell')
   return cell.h_
end

local function first_set(cell, h)
   assert(cell, 'empty cell')
   cell.h_ = h
   return cell
end

local function rest(cell)
   assert(cell, 'empty cell')
   return cell.t_
end

local function rest_set(cell, t)
   assert(cell, 'empty cell')
   cell.t_ = t
   return cell
end

-- fixed queue

-- circular queues intensively use modulo arithmetic, so 0 based
-- indexing is more natural fit here

local function fq_new(size)
   local size = size + 1
   return { buff_ = mk_arr(size)
	  ; beg_ = 0
	  ; end_ = 0
	  ; sz_  = size
          }
end

local function fq_is_empty(q)
   return q.beg_ == q.end_
end

local function fq_is_full(q)
   return inc_mod(q.end_, q.sz_) == q.beg_
end

local function fq_front(q)
   assert(not fq_is_empty(q), 'queue is empty')
   return q.buff_[q.beg_]
end

local function fq_enqueue(q, val)
   assert(not fq_is_full(q), 'queue is full')
   q.buff_[q.end_] = val
   q.end_ = inc_mod(q.end_, q.sz_)
end

local function fq_dequeue(q)
   assert(not fq_is_empty(q), 'queue is empty')
   local ret = fq_front(q)
   q.beg_ = inc_mod(q.beg_, q.sz_)
   return ret
end

-- queue
local function q_new()
   return { beg_ = nil
	  ; end_ = nil
          }
end

local function q_is_empty(q)
   return not q.end_
end

local function q_front(q)
   assert(not q_is_empty(q), 'set queue is empty')
   return first(q.end_)
end

local function q_enqueue(q, val)
   local new_beg_ = list(val)
   if q.beg_ then
      rest_set(q.beg_, new_beg_);
      q.beg_ = new_beg_
   else
      q.beg_ = new_beg_
      q.end_ = new_beg_
   end
end

local function q_dequeue(q)
   assert(not q_is_empty(q), 'set queue is empty')
   local ret = q_front(q)
   q.end_ = rest(q.end_)
   if not q.end_ then q.beg_ = nil end
   return ret
end

-- iface

local fq_mtds = {
   is_empty = fq_is_empty,
   is_full  = fq_is_full,
   front    = fq_front,
   enqueue  = fq_enqueue,
   dequeue  = fq_dequeue,
}

local q_mtds = {
   is_empty = q_is_empty,
   front    = q_front,
   enqueue  = q_enqueue,
   dequeue  = q_dequeue
}

return {
   fixed_queue_new = function(size)
      size = size or 1
      local q = fq_new(size)
      setmetatable(q, { __index = fq_mtds })
      return q
   end
   ;
   queue_new = function()
      local q = q_new()
      setmetatable(q, { __index = q_mtds })
      return q
   end

}
