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
lsp_status.setup()

local function on_attach(client)
  -- ... other stuff

  -- define an handler for the method `$/progress`
  lsp_status.on_attach(client)
end

lspconfig.rust_analyzer.setup {    -- Rust
  on_attach = on_attach,
  -- add the "Work Done progress" reporting to capabilities
  capabilities = lsp_status.capabilities
}
```

### get the status

The status is either the LSP client name or, if it exists, a text built from the last "Work done progress" notification.

See the [spec](https://microsoft.github.io/language-server-protocol/specifications/specification-current/#workDoneProgress) for the details.

```lua
require'lsp_status'.status()
```
You can listen to the autocommand event `LspStatusChanged` to get notified when the status is updated.

### license
Mozilla Public License 2.0
