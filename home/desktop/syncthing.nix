# Syncthing: keeps folders identical across your own devices (t14s, the Mac
# mini), peer to peer, no server in the middle. It is sync, not backup: a
# file deleted on one device is deleted on all of them.
#
# Workstations only. Never on a server: a folder shared with spectre would
# let a compromised spectre write files onto your devices, which is exactly
# what the tailnet policy and fleet's LAN egress rule exist to prevent.
#
# Home Manager runs it as a user service (systemd on Linux, launchd on the
# Mac); the web UI is http://127.0.0.1:8384 on each machine. Pairing and
# folders are done in that UI, not here: each device's ID is generated on
# its first start, so there is nothing to declare yet. overrideDevices and
# overrideFolders are off so what you set up in the UI survives every
# `just sync`. When the set of devices settles, they can move here.
#
# Pairing, once per pair of machines: on one, Actions -> Show ID; on the
# other, Add Remote Device with that ID. Under Advanced, set Addresses to
# `dynamic, tcp://<tailnet name>:22000` (e.g. tcp://mini:22000) so they find
# each other away from home too, over the tailnet.
{ ... }:

{
  services.syncthing = {
    enable = true;
    overrideDevices = false;
    overrideFolders = false;
  };
  custom.smoke.syncthing = "syncthing --version";
}
