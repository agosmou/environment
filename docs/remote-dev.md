# Developing On A Server

Code, tools, and running processes live on the server (`spectre`); the
laptop is the screen. A terminal over SSH for the editor, and one of three
routes for seeing what the code serves in the laptop's browser. Nothing
below needs installing: Tailscale, SSH, tmux and Ghostty's shell integration
are already managed by this repository and the
[fleet](https://github.com/agosmou/fleet) repository.

## The terminal

```bash
ssh spectre
tmux new -s <project>       # or prefix s on an existing session (docs/tmux.md)
```

tmux is what makes the connection disposable: close the laptop, and the
editor, the dev server, and their scrollback are still there on the next
`ssh spectre` and `tmux attach`.

### `missing or unsuitable terminal: xterm-ghostty`

Ghostty announces itself as `TERM=xterm-ghostty`, ssh forwards `TERM`, and
tmux refuses to start on a machine that has no terminfo entry for it (a
plain shell does not check, which is why everything else works). Managed:
`home/terminal/ghostty.nix` turns on Ghostty's `ssh-terminfo` and `ssh-env`
shell-integration features, which wrap `ssh` so it installs the terminfo on
the remote the first time and falls back to `TERM=xterm-256color` when it
cannot ([Ghostty reference](https://ghostty.org/docs/config/reference#shell-integration-features)).

Those features are baked into each terminal window when it opens, so a
Ghostty started before that setting landed does not have them until it is
restarted. Check, in a local shell:

```bash
echo $GHOSTTY_SHELL_FEATURES    # must list ssh-env and ssh-terminfo
type ssh                        # "ssh is a function": the wrapper is active
```

One-off, for any machine, from a machine that has the entry
([Ghostty terminfo](https://ghostty.org/docs/help/terminfo)):

```bash
infocmp -x xterm-ghostty | ssh <name> -- tic -x -
```

It lands in `~/.terminfo` on the remote and stays.

## Seeing a dev server in the browser

Three routes. Pick by what the code cares about, not by habit.

| Route | Browser URL | Use when |
|---|---|---|
| Tailnet, directly | `http://spectre:5173` | Default. Also reachable from the phone and the Mac. |
| `tailscale serve` | `https://spectre.<tailnet>.ts.net` | The server only listens on localhost and you do not want to change that; or you need HTTPS. |
| `ssh -L` | `http://localhost:5173` | The code checks the origin: OAuth callbacks registered to `localhost`, `Secure` cookies, a CORS allowlist. |

The server's firewall (fleet's `ufw` role) allows everything arriving over
`tailscale0` and denies everything else inbound except SSH from the LAN. So
a port opened on the server is visible to the tailnet and to nothing else,
with no firewall change on either route. Tailscale itself:
`docs/tailscale.md`.

### Tailnet, directly

The server must listen on all interfaces, not only loopback. Defaults
differ:

| Server | Default | All interfaces |
|---|---|---|
| Vite | localhost | `vite --host` ([docs](https://vite.dev/config/server-options.html#server-host)) |
| uvicorn / FastAPI | 127.0.0.1 | `uvicorn app:app --host 0.0.0.0` ([docs](https://uvicorn.org/settings/)) |
| Next.js | 0.0.0.0 | nothing to do ([docs](https://nextjs.org/docs/app/api-reference/cli/next#next-dev-options)) |

Then `http://spectre:<port>` from any tailnet device; MagicDNS resolves the
name. `ss -ltn` on the server shows what is listening and on which address.

### `tailscale serve`

tailscaled answers the connection and proxies it to a local port, so the
server can stay on localhost. It also gets a real certificate
([Serve](https://tailscale.com/kb/1312/serve),
[CLI](https://tailscale.com/kb/1242/tailscale-serve)).

```bash
sudo tailscale set --operator=$USER   # once: lets your user run serve without sudo
tailscale serve --bg 5173             # https://spectre.<tailnet>.ts.net → localhost:5173
tailscale serve status
tailscale serve reset                 # stop
```

`--bg` keeps it across logouts and reboots; without it, serve runs in the
foreground and stops with Ctrl-C. HTTPS needs certificates enabled once for
the tailnet: admin console → DNS → **HTTPS Certificates**. Until then,
`tailscale serve --http=8080 5173` gives plain `http://spectre:8080`.

### `ssh -L`

Forwards a laptop port to a server port through the SSH connection. The
browser sees `localhost`, which is the point.

```bash
ssh -N -L 5173:localhost:5173 spectre     # -N: no shell, just the forward
```

Two ways to avoid a pane per tunnel:

- **Add a forward to the session already open.** At the start of a line,
  type `~C`, then `-L 5173:localhost:5173`, Enter
  ([ssh escape characters](https://man.openbsd.org/ssh#ESCAPE_CHARACTERS)).
  Works while tmux is attached, because the escape is read by the local
  `ssh`, not by anything on the server.
- **Ports you always want.** In `~/.ssh/config.local` on the laptop (per
  machine, not managed; `docs/remote-access.md`):

  ```
  Host spectre
    LocalForward 5173 localhost:5173
    LocalForward 8000 localhost:8000
  ```

  Every `ssh spectre` then carries them. A second session only warns that
  the port is in use; the first one keeps it.

A forward dies with its connection, so it is the laptop-sleep-sensitive
route; the other two are not.

## When it fails

| Symptom | Meaning | Fix |
|---|---|---|
| `missing or unsuitable terminal: xterm-ghostty` | No terminfo on the server | Above: restart Ghostty, or the `infocmp \| tic` line |
| `http://spectre:5173` times out, `ss -ltn` shows `127.0.0.1:5173` | Server listens on loopback only | `--host 0.0.0.0` (or the framework's equivalent), or `tailscale serve` |
| `http://spectre:5173` times out, `ss -ltn` shows `0.0.0.0:5173` | The laptop is not on the tailnet, or the name does not resolve | `tailscale status` on both; `tailscale ping spectre` |
| `bind: Address already in use` on `ssh -L` | Another ssh already holds that laptop port | Fine if it is yours; `ss -ltnp \| grep 5173` locally to see whose |
| `tailscale serve` says access denied | Not root or operator | `sudo tailscale set --operator=$USER`, once |
