# Postgres client tools: psql, pg_dump, pg_restore, pg_isready. For talking
# to a database that lives elsewhere (Neon, a container) and for the backup
# scripts of projects that keep a Postgres ledger (money-trees). No server is
# run from here -- the package ships one, but nothing starts it.
#
# Why the version is pinned: pg_dump refuses to dump a server newer than
# itself, and the managed databases are on 18. Bump this when they move.
{ pkgs, ... }:

{
  home.packages = [ pkgs.postgresql_18 ];
  custom.smoke.pg_dump = "pg_dump --version";
}
