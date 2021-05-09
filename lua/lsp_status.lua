--[[ This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]

local cmd = vim.cmd
local lsp = vim.lsp
local api = vim.api
local spinner = {'▖', '▘', '▝', '▗'}
local clients = {} -- key by client ID and bufnr (meta)
local works = {} -- key by token
local status = {} -- key by bufnr

local function push_status(work)
  local current = work.client_name
  current = string.format('%s %s', current, work.title)
  if work.message then current = string.format('%s %s', current, work.message) end
  if work.percentage then current = string.format('%s %s%%', current, work.percentage) end
  if work.frame then
    current = string.format('%s %s', current, spinner[work.frame])
  end
  if work.done then
    current = string.format('%s done', current)
  end
  if not status[work.bufnr] then
    status[work.bufnr] = {}
  end
  table.insert(status[work.bufnr], current)
end

local function clean_work_done()
  for token, work in pairs(works) do
    if work.done == true then works[token] = nil end
  end
end

local function clean_stopped_clients()
  for token, work in pairs(works) do
    if lsp.client_is_stopped(work.client_id) then
      works[token] = nil
      clients[work.client_id] = nil
    end
  end
end

local function progress_callback(_, _, msg, client_id)
  local val = msg.value
  if val.kind then
    if val.kind == 'begin' then
      local client = clients[client_id] or lsp.get_client_by_id(client_id)
      if not client then return end
      works[msg.token] = {
        client_id = client_id,
        client_name = client.name,
        bufnr = client.bufnr or api.nvim_get_current_buf(),
        title = val.title,
        message = val.message,
        percentage = val.percentage,
        frame = 1
      }
    elseif val.kind == 'report' then
      if val.message then
        works[msg.token].message = val.message
      end
      works[msg.token].percentage = val.percentage
      local prev_frame = works[msg.token].frame
      works[msg.token].frame = prev_frame < #spinner and prev_frame + 1 or 1
    elseif val.kind == 'end' then
      works[msg.token].message = val.message
      works[msg.token].frame = nil
      works[msg.token].done = true
    end
    push_status(works[msg.token])
  end
  cmd 'doautocmd User LspStatusChanged'
  clean_work_done()
end

local function get_status(bufnr)
  clean_stopped_clients()
  if not bufnr then bufnr = 0 end
  local client = clients[bufnr]
  if not client then return '' end
  if vim.tbl_isempty(status) or not status[bufnr] then
    return client.name
  end
  local temp = status[bufnr][#status[bufnr]]
  status[bufnr] = nil
  return temp
end

local capabilities = lsp.protocol.make_client_capabilities()
capabilities.window = capabilities.window or {}
capabilities.window.workDoneProgress = true

local function setup()
  lsp.handlers['$/progress'] = progress_callback
  local metaindex = function(tbl, key)
    for _, data in pairs(tbl) do
      if data.bufnr == key then
        return data
      end
    end
    return nil
  end
  setmetatable(clients, {__index = metaindex})
end

local function on_attach(client, bufnr)
  clients[client.id] = {
    name = client.name,
    bufnr = bufnr,
  }
  cmd 'doautocmd User LspStatusChanged'
end

return {
  setup = setup,
  on_attach = on_attach,
  capabilities = capabilities,
  status = get_status,
}
