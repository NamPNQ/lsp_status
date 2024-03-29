## lsp_status

Retreive the status of [nvim](https://neovim.io/)'s builtin LSP clients.

### install

```
paq 'doums/lsp_status'
```

### setup
```lua
local lspconfig = require'lspconfig'
local lsp_status = require'lsp_status'

-- register an handler for `$/progress` method
lsp_status.setup()

local function on_attach(client)
  -- ... other stuff

  -- get client name
  lsp_status.on_attach(client)
end

lspconfig.rust_analyzer.setup {  -- Rust Analyzer setup
  on_attach = on_attach,
  -- add `window/workDoneProgress` to default client capabilities
  capabilities = lsp_status.capabilities
}
```

### get status

The status is either the LSP client name or, if it exists, a text built from the last "Work done progress" notification.

See the [spec](https://microsoft.github.io/language-server-protocol/specifications/specification-current/#workDoneProgress) for details.

```lua
require'lsp_status'.status()
```
Listen to the autocommand event `LspStatusChanged` to get notified when the status is updated.

### license
Mozilla Public License 2.0
