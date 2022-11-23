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
    -- The only key that can be 40 bytes is the SHA-1 of the commit
    -- we want to store the hash as a value in this case
    if string.len(key) == 40 then
      blame['hash'] = key
    else
      blame[key] = value
    end
  end
  handle:close()
  return blame
end

-- should make it relative to user. Also, would be nice to display it like in
-- gitlens, e.g (4 days ago)
local function format_time(t)
  local d = os.date('%d/%m/%y', t)
  return d
end

local function render_output(hash, epoch, author, summary)
  local t = format_time(epoch)
  if hash == emptyHash then
    return author .. ' • ' .. t
  end
  return author .. ' • ' .. t .. ' • ' .. summary
end

M.blame = function(blame_ns)
  -- use vim.fn.system for sys calls
  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  local filename = vim.api.nvim_buf_get_name(0)
  local info = blame_output(filename, cursor)
  local pretty = render_output(info['hash'], info['author-time'], info['author'], info['summary'])
  local hl = vim.api.nvim_set_hl(blame_ns, 'BlameNvim', {})
  local extOpts = {
    id = 1,
    virt_text = { { pretty, vim.api.nvim_get_hl_id_by_name('BlameNvim') } },
    virt_text_pos = 'eol',
  }
  vim.api.nvim_buf_set_extmark(0, blame_ns, cursor, 0, extOpts)
end

M.clear_output = function(ns)
  vim.api.nvim_buf_del_extmark(0, ns, 1)
end

M.setup = function()
  -- Get cursor from current window, we only care about the row
  local blame_ns = vim.api.nvim_create_namespace('BlameNvim')
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    callback = function()
      M.clear_output(blame_ns)
    end,
  })
  vim.api.nvim_create_autocmd({ 'CursorHold' }, {
    callback = function()
      M.blame(blame_ns)
    end,
  })
end

return M
