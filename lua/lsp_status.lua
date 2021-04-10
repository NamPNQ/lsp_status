--[[ This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]

local cmd = vim.cmd
local lsp = vim.lsp

local clients = {}
local messages = {}

local function progress_callback(_, _, msg, client_id)
  local val = msg.value
  local message = clients[client_id] or client_id
  if val.kind then
    if val.kind == 'begin' then
      message = string.format('%s %s', message, val.title)
      if val.message then
        message = string.format('%s %s', message, val.message)
      end
      if val.percentage then
        message = string.format('%s %s%%', message, val.percentage)
      end
    elseif val.kind == 'report' then
      if val.message then
        message = string.format('%s %s', message, val.message)
      end
      if val.percentage then
        message = string.format('%s %s%%', message, val.percentage)
      end
    elseif val.kind == 'end' then
      if val.message then
        message = string.format('%s %s', message, val.message)
      end
    end
    table.insert(messages, message)
    cmd 'doautocmd User LspStatusChanged'
  end
end

local function get_status()
  local message = messages[#messages]
  messages = {}
  return message or clients[#clients] or ''
end

local capabilities = lsp.protocol.make_client_capabilities()
capabilities.window = capabilities.window or {}
capabilities.window.workDoneProgress = true

local function setup()
  lsp.handlers['$/progress'] = progress_callback
end

local function on_attach(client)
  clients[client.id] = client.name
  cmd 'doautocmd User LspStatusChanged'
end

return {
  setup = setup,
  on_attach = on_attach,
  capabilities = capabilities,
  status = get_status,
}
