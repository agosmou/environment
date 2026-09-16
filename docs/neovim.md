# Neovim

Kickstart-based configuration with a `custom/` layer on top. Nix installs
Neovim and every external tool it needs; the Lua is real source, linked into
`~/.config/nvim` unchanged.

## Layout

```
home/neovim/
├── default.nix           installs Neovim, language servers, formatters, debug adapters
├── workstation.nix       extra tools for PDF/image preview; workstations only
├── nvim-pack-lock.json   pinned plugin revisions
└── config/               ~/.config/nvim
    ├── init.lua          Kickstart, lightly edited
    └── lua/
        ├── kickstart/plugins/   Kickstart's optional plugins (debug, gitsigns, lint, neo-tree)
        └── custom/
            ├── options.lua      editor settings
            ├── keymaps.lua      the keys below
            └── plugins/         one file per plugin added here
```

## Adding things

| To add | Where |
|---|---|
| A language server, formatter, or linter | `extraPackages` in `default.nix`, then wire it in `init.lua`'s LSP/conform/lint sections. No Mason: Nix owns every executable. |
| A plugin | A file in `config/lua/custom/plugins/` using `vim.pack.add`; then update the lock (below) |
| A keymap | `config/lua/custom/keymaps.lua` |

Plugins use Neovim's built-in `vim.pack`, pinned by `nvim-pack-lock.json`.
Home Manager copies the lock into `~/.config/nvim` as a writable file on every
apply (vim.pack rewrites it). To update plugins: run `:lua vim.pack.update()`
in Neovim, review, copy `~/.config/nvim/nvim-pack-lock.json` back into the
repository, `just apply`.

Plugin checkouts and Tree-sitter parsers live in `~/.local/share/nvim` and are
not managed; delete that directory to reset them.

## Keys added here

Leader is Space. Kickstart's own keys are unchanged; `<leader>sk` searches
all of them.

**Basics**

| Key | Does |
|---|---|
| `jk` (insert) | Escape |
| `;;` / `,,` (insert) | Append `;` / `,` to the line and stay in insert |
| `Ctrl-s`, `<leader>w` | Save |
| `<leader>qq` | Quit all |
| `<leader>kd` | Clear search highlight |
| `H` / `L` | Start / end of line |
| `Ctrl-d` / `Ctrl-u`, `n` / `N` | As usual, but keep the cursor line centered |
| `<leader>p` | Paste from the yank register (ignores deletes) |
| `<leader>P` (visual) | Paste over selection without yanking it |
| `<leader>uw` | Toggle line wrap |
| `<leader>uf` | Toggle format-on-save (off by default) |
| `<leader>ut` | Pick a colorscheme; the choice persists |
| `<leader>U` | Undo tree |

**Buffers and quickfix**

| Key | Does |
|---|---|
| `[b` / `]b` | Previous / next buffer |
| `<leader>bb` | Last buffer |
| `<leader>bd` | Delete buffer |
| `<leader>cn` / `<leader>cp` | Next / previous quickfix item |

**Code (LSP)**

| Key | Does |
|---|---|
| `gd` `gD` `gr` `gI` `gy` | Definition, declaration, references, implementation, type definition |
| `<leader>cr` | Rename |
| `<leader>ca` | Code action |
| `<leader>cf`, `<leader>f` | Format (conform) |
| `<leader>cd` | Diagnostic for the current line |
| `<leader>xx` / `<leader>xX` | Trouble: all diagnostics / this buffer |
| `<leader>xs` | Trouble: symbols |

**Git**

| Key | Does |
|---|---|
| `<leader>gg` | lazygit |
| `<leader>gd` | Diffview |
| `<leader>gh` / `<leader>gH` | File history: this file / repository |

**Harpoon** (pin files, jump between them)

| Key | Does |
|---|---|
| `<leader>a` | Pin current file |
| `<leader>m`, `Ctrl-e` | Pin list |

**Debug** (Go via Delve, Rust via CodeLLDB, Python via debugpy)

| Key | Does |
|---|---|
| `<leader>db` / `<leader>dB` | Toggle breakpoint / conditional breakpoint |
| `<leader>dc` | Start or continue |
| `<leader>dn` / `<leader>di` / `<leader>do` | Step over / into / out |
| `<leader>dt` | Terminate |
| `<leader>du` | Toggle the debug UI |
| `<leader>de` | Evaluate expression under cursor or selection |
| `<leader>dpm` / `<leader>dpc` | Python: debug test method / class |

**tmux**: `Ctrl-h/j/k/l` move between Neovim splits and tmux panes as one
space (vim-tmux-navigator).
