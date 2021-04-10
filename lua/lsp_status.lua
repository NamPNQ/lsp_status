--[[ This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]

local cmd = vim.cmd
local lsp = vim.lsp

local spinner = {'▖', '▗', '▝', '▘'}
local clients = {}
local messages = {}
local last_token

local function progress_callback(_, _, msg, client_id)
  local val = msg.value
  if val.kind then
    last_token = msg.token
    if val.kind == 'begin' then
      messages[msg.token] = {
        client_name = clients[client_id] or '',
        title = val.title,
        message = val.message,
        percentage = val.percentage,
        frame = 1
      }
    elseif val.kind == 'report' then
      if val.message then
        messages[msg.token].message = val.message
      end
      messages[msg.token].percentage = val.percentage
      local prev_frame = messages[msg.token].frame
      messages[msg.token].frame = prev_frame < #spinner and prev_frame + 1 or 1
    elseif val.kind == 'end' then
      messages[msg.token].message = val.message
      messages[msg.token].frame = nil
      messages[msg.token].done = true
    end
    cmd 'doautocmd User LspStatusChanged'
  end
end

local function get_status()
  local data = messages[last_token]
  local status = data.client_name
  if data.frame then
    status = spinner[data.frame]
  end
  status = string.format('%s %s', status, data.title)
  if data.message then status = string.format('%s %s', status, data.message) end
  if data.percentage then status = string.format('%s %s%%', status, data.percentage) end
  if data.done then
    status = string.format('%s DONE', status)
  end
  return ''
end

local capabilities = lsp.protocol.make_client_capabilities()
capabilities.window = capabilities.window or {}
capabilities.window.workDoneProgress = true

local function setup()
  lsp.handlers['$/progress'] = progress_callback
end

local function on_attach(client)
  print(client.name)
  clients[client.id] = client.name
  cmd 'doautocmd User LspStatusChanged'
end

return {
  setup = setup,
  on_attach = on_attach,
  capabilities = capabilities,
  status = get_status,
}
