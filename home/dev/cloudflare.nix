# Cloudflare's command-line tools, both Cloudflare's own:
#   cloudflared  tunnels: expose a local port through Cloudflare, or reach a
#                private service (`cloudflared tunnel ...`, `cloudflared access`)
#   wrangler     Workers and Pages: develop and deploy (`wrangler dev`,
#                `wrangler deploy`). A Workers project usually pins its own
#                wrangler in package.json, which wins inside the project; this
#                global one is for `wrangler login` and scratch work.
#
# Both log in to a Cloudflare account; that state stays on the machine.
{ pkgs, ... }:

{
  home.packages = [
    pkgs.cloudflared
    pkgs.wrangler
  ];
  custom.smoke = {
    cloudflared = "cloudflared --version";
    wrangler = "wrangler --version";
  };
}
