# To Do

Short list of what is next. Done items are deleted, not ticked.

## Next

- Tailscale, after the install lands: `sudo tailscale up` on the laptop; check
  the admin console for the Mac mini; disable key expiry on machines you do
  not sit at. Then decide whether Tailscale's Mullvad exit nodes replace the
  standalone Mullvad app (`docs/tailscale.md`, "Mullvad and Tailscale
  together").
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

- Supply-chain security, per project, when there is a project with
  dependencies worth auditing: `cargo-deny` and `cargo-audit` as the Rust
  baseline, `cargo-vet` for reviewed-dependency audits, `osv-scanner` across
  ecosystems, Trivy for container images. Project flakes and CI, not this
  repository, unless one turns out to be an everyday tool.

Things to try, not commitments.

- Tiling window managers, from least to most change:
  - GNOME **Tiling Shell** extension: tiling inside GNOME, nothing else
    changes. Try this first.
  - **Sway**: a separate Wayland session, i3-style config; same model as
    AeroSpace on the Mac. Fedora ships it (`sway`, `sway-config-fedora`).
  - **Hyprland**: also a separate session, more animation and more config
    churn between releases. Fedora ships it too.
