# To Do

Short list of what is next. Done items are deleted, not ticked.

## Next

- Tailscale: `tailscale` in `platform/fedora/packages` and `tailscaled` in the
  Fedora bootstrap, the `tailscale-app` cask, doctor checks, and the
  Tailscale section of `docs/remote-access.md`. Then `sudo tailscale up` on
  each machine and `Host hagp` in `~/.ssh/config.local`.
- Cloudflare: decide which product (cloudflared, WARP, or wrangler), then add
  it.
- ty (Astral's Python type checker and language server): still 0.0.x beta as
  of 2026-09. Revisit as a pyrefly replacement once it ships a stable release;
  it is the same authors as uv and ruff.
- Claude Desktop on Fedora: Anthropic's Linux beta ships .deb only. Add the
  rpm to `platform/fedora/packages` when one exists.
- Bootstrap end to end in CI: a Fedora container with systemd and an `ag`
  user runs the real `./bootstrap`, then `doctor` must be clean.
- Branch protection on `main` requiring the three CI checks.
- `CONTEXT.md` glossary and one-paragraph ADRs under `docs/adr/`.

## Explore

Things to try, not commitments.

- Tiling window managers, from least to most change:
  - GNOME **Tiling Shell** extension: tiling inside GNOME, nothing else
    changes. Try this first.
  - **Sway**: a separate Wayland session, i3-style config; same model as
    AeroSpace on the Mac. Fedora ships it (`sway`, `sway-config-fedora`).
  - **Hyprland**: also a separate session, more animation and more config
    churn between releases. Fedora ships it too.
