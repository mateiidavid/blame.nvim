local M = {}

local gitComm = 'git --no-pager blame '
local blameArg = '--porcelain --line-porcelain -L '

local function git_iter(stream)
  local pattern = '(%w+%p*%w+)%s*(.+)'
  local line = stream:read()
  local c = 1
  return function()
    -- If we have nothing left in the stream or we've reached the 12th line,
    -- return
    if stream:read(0) == nil or c == 12 then
      return nil
    end
    line = stream:read()
    local _, _, key, value = string.find(line, pattern)
    c = c + 1
    return key, value
  end
end

local function blame_output(filename, cursor)
  local args = blameArg .. cursor .. ',+1 -- ' .. filename
  local comm = gitComm .. args
  local handle = assert(io.popen(comm))
  local blame = {}
  for key, value in git_iter(handle) do
    blame[key] = value
  end
  handle:close()
  return blame
end

M.blame = function()
  -- Get cursor from current window, we only care about the row
  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  local filename = vim.api.nvim_buf_get_name(0)
  local info = blame_output(filename, cursor)
  print(info.author)
end

return M
