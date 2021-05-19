--[[ This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]

local cmd = vim.cmd
local lsp = vim.lsp
local spinner = {'▖', '▘', '▝', '▗'}
local clients = {} -- key by client ID and bufnr (meta)
local works = {} -- key by token and bufnr (meta)

local function build_status(work)
  local status = work.client_name
  status = string.format('%s %s', status, work.title)
  if work.message then status = string.format('%s %s', status, work.message) end
  if work.percentage then status = string.format('%s %s%%', status, work.percentage) end
  if work.frame then
    status = string.format('%s %s', status, spinner[work.frame])
  end
  return status
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
        bufnr = client.bufnr,
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
      works[msg.token] = nil
    end
  end
  cmd 'doautocmd User LspStatusChanged'
end

local function get_status(bufnr)
  clean_stopped_clients()
  if not bufnr then
    bufnr = 0
  end
  local client = clients[bufnr]
  if not client then return '' end
  local work = works[bufnr]
  if work then
    return build_status(work)
  end
  return client.name
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
  setmetatable(works, {__index = metaindex})
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
