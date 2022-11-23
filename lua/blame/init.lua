local M = {}

local gitComm = 'git --no-pager blame '
local blameArg = '--porcelain --line-porcelain -L '
local emptyHash = '0000000000000000000000000000000000000000'

-- TODO: we should treat the hash separately possibly (i.e extract it).
local function git_iter(stream)
  local pattern = '(%w+%p*%w+)%s*(.+)'
  local c = 1
  return function()
    -- If we have nothing left in the stream return
    if stream:read(0) == nil then
      return nil
    end
    local line = stream:read()
    local _, _, key, value = string.find(line, pattern)
    c = c + 1

    return key, value
  end
end

-- TODO: if hash is empty (0000) don't display anything
-- TODO: check file type. Don't run for scratch buffers (ft = '')
--  fh
local function blame_output(filename, cursor)
  local args = blameArg .. cursor .. ',+1 -- ' .. filename
  local comm = gitComm .. args
  local handle = assert(io.popen(comm))
  local blame = {}
  for key, value in git_iter(handle) do
    print(key)
    -- The only key that can be 40 bytes is the SHA-1 of the commit
    -- we want to store the hash as a value in this case
    if string.len(key) == 40 then
      blame['hash'] = key
    end
    blame[key] = value
  end
  handle:close()
  return blame
end

M.blame = function()
  -- Get cursor from current window, we only care about the row
  local blame_ns = vim.api.nvim_create_namespace('blame-nvim')
  -- use vim.fn.system for sys calls
  print('namespace', blame_ns)
  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  local filename = vim.api.nvim_buf_get_name(0)
  local info = blame_output(filename, cursor)
  print(info.hash)
  --vim.api.nvim_buf_set_virtual_text(0, blame_ns, cursor, 0, {end_row: })
end

return M
