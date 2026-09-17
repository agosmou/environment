# To Do

Short list of what is next. Done items are deleted, not ticked.

## Next

- Tailscale: `tailscale` in `platform/fedora/packages` and `tailscaled` in the
  Fedora bootstrap, the `tailscale-app` cask, doctor checks, and the
  Tailscale section of `docs/remote-access.md`. Then `sudo tailscale up` on
  each machine and `Host hagp` in `~/.ssh/config.local`.
- Cloudflare: decide which product (cloudflared, WARP, or wrangler), then add
  it.
- black: keep only if working on repos that configure black; otherwise drop it
  and simplify the Python formatter choice in `init.lua` to `ruff_format`.
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
