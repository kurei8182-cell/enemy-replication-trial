# wkey-enemy-spawner

Take-home assignment for WKEY Studios Gameplay Engineer role.

Enemy spawner system with custom buffer-packed replication over UnreliableRemoteEvent.

## Run locally

- Requires Rojo 7.4.4 (pinned via Aftman)
- `aftman install` to grab the toolchain
- `rojo serve` and connect via the Studio plugin
- Workspace needs an anchored Part named `Platform`, size 50×50 studs

## Structure

- `src/server/`: spawner, chase/targeting, snapshot broadcast, admin handler
- `src/client/`: rendering, interpolation, click handling, admin UI
- `src/shared/`: Config, Types, Remotes, Snapshot encoder/decoder

## Approach

See [APPROACH.md](./APPROACH.md).

## Live place

https://www.roblox.com/games/126334761750442/WKEY-Enemy-Spawner-Trial
