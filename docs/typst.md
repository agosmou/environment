# Typst

Writing documents (letters, papers, slides, one-page PDFs) from plain text.
Workstations only; a server has no use for it.

## What is installed

| Command | Package | From |
|---|---|---|
| `typst` | `pkgs.typst` | `home/dev/typst.nix` |
| `tinymist` | `pkgs.tinymist` | same file, the language server Neovim starts on `.typ` files |

Both come from nixpkgs at the version in `flake.lock`, so `just update`
moves them like everything else. The
[typst-flake](https://github.com/typst/typst-flake) was considered and
skipped: it exists to build unreleased Typst commits, and nixpkgs already
carries the current release.

## Writing a document

```bash
mkdir -p ~/docs/letter && cd ~/docs/letter
nvim letter.typ          # tinymist attaches: completion, hover, diagnostics
typst compile letter.typ # writes letter.pdf next to it
typst watch letter.typ   # same, on every save; leave it in a tmux pane
```

Open the PDF in the desktop viewer (Evince on Fedora, Preview on the Mac;
both reload when the file changes), or inside Neovim with `:PDFReader`
(`home/neovim/config/lua/custom/plugins/pdfreader.lua`).

A `.typ` file is a plain text file: keep the source in a repository, keep the
PDF out of it (`*.pdf` in `.gitignore`). Fonts: Typst embeds whatever it finds
in the system font directories plus its own bundled ones; `typst fonts` lists
them. A font the document names but the machine lacks silently falls back, so
check the list before blaming the template.

Templates and packages come from the [Typst Universe](https://typst.app/universe)
and are downloaded on first use into `~/.cache/typst` (Linux) or
`~/Library/Caches/typst` (Mac): `#import "@preview/<name>:<version>": *` at
the top of the file is the whole step. That cache is runtime state, not
managed here.

## In Neovim

- `.typ` is detected as the `typst` filetype by Neovim itself; the
  Tree-sitter parser installs on the first open (`init.lua`, SECTION 8).
- tinymist is registered in `init.lua`'s LSP table with
  `formatterMode = 'typstyle'`, so `<leader>f` formats through the server;
  no separate formatter binary.
- The server can export without the CLI: `:LspTinymistExportPdf` and
  friends are defined by nvim-lspconfig. `typst watch` is still the simpler
  loop for a document you are actively editing.
- doctor checks `typst` and `tinymist` are reachable from inside Neovim,
  the same way it checks `gopls` (`custom.neovimTools` in `typst.nix`).
