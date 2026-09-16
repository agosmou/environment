# keyd: the key remapping daemon that makes Caps Lock act as Control when
# held and Escape when tapped. Fedora workstation only.
#
# This file only BUILDS the binary and puts it in ~/.nix-profile/bin. It does
# not run it: keyd must run as root, so platform/fedora/bootstrap.sh copies
# the binary to /usr/local/bin and installs it as a system service. The
# mapping itself is in platform/fedora/keyd/default.conf.
{ pkgs, ... }:

let
  # A statically linked build, because a Fedora system service cannot load a
  # dynamic linker out of /nix/store (SELinux forbids it). pkgsStatic builds
  # against musl instead of glibc, with no shared libraries.
  #
  # Two patches on top:
  #   - keyd tries to switch itself to real-time scheduling and lock its
  #     memory at start. Under musl on this host those calls return ENOSYS
  #     and keyd exits. Replace the three checks with `if (0)` so they are
  #     skipped; remapping works fine under the normal scheduler.
  #   - Drop the package's own /etc so it cannot shadow the config the
  #     bootstrap installs.
  keydStatic = pkgs.pkgsStatic.keyd.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/daemon.c \
        --replace-fail "if (sched_getparam(0, &sp)) {" "if (0) {" \
        --replace-fail "if (sched_setscheduler(0, SCHED_FIFO, &sp)) {" "if (0) {" \
        --replace-fail "if (mlockall(MCL_CURRENT | MCL_FUTURE)) {" "if (0) {"
    '';
    postInstall = ''
      rm -rf $out/etc
    '';
  });
in
{
  home.packages = [ keydStatic ];
  custom.smoke.keyd = "keyd -v";
}
