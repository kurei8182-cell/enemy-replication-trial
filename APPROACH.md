# Approach

Take-home for WKEY Studios: enemy spawner with custom replication.

## What I prioritized

The spec lists a bunch of requirements, but the grading criteria made the real target obvious: replication cost at the 20-enemy cap, with an explicit mention of the Recv stat and a heavy encouragement to use a custom replication system. Everything else (spawner loop, chase, click-to-print-ID, Kill All UI) is entry-level gameplay programming. The differentiator was going to be whether I actually built the custom replication layer or fell back on default Roblox replication and called it a day.

So I designed the whole thing around that constraint from the start. Enemies are server-side Lua data with no Instances attached, and the server broadcasts packed position snapshots to clients via an UnreliableRemoteEvent. Clients own the visual Parts independently and interpolate between snapshots.

## Architecture

Server owns the authoritative enemy table (id, position, velocity, targetUserId, variation, lastAttackAt). No Humanoids, no Parts per enemy. All simulation runs in a single RunService.Heartbeat loop that iterates the enemy table once per frame.

Shared modules for Config, Types, Remotes, and the Snapshot encoder/decoder. One-script hierarchy per the job posting's preference, so no Knit, no Matter, no component systems.

Client subscribes to three remotes: EnemySpawned (reliable, builds the visual Part with variation applied), EnemyRemoved (reliable, destroys the Part), and EnemySnapshot (unreliable, 15Hz position updates). A RenderStepped loop lerps each Part's CFrame toward its latest snapshot target.

## The replication layer

Snapshot format: 2 byte header plus 8 bytes per enemy (u16 id, i16 x*100, i16 y*100, i16 z*100).

At the 20 enemy cap that's 162 bytes per snapshot. At 15Hz that's roughly 2.4 KB/s outbound per client at full load. Positions are quantized to 0.01 stud precision, which fits comfortably in i16 range (±327 studs) against a 50x50 platform.

Dropped packets are fine because the next snapshot arrives ~66ms later. That's what UnreliableRemoteEvent is for: no retransmit, no head-of-line blocking.

Compared to leaving 20 Parts on the server and letting default Roblox replication handle CFrame updates, this is dramatically lighter. Default replication sends full CFrame data (position plus quaternion rotation plus overhead) at its own rate, and I didn't want to be at the mercy of whatever it decides is "good enough."

## Chase and targeting

Target re-evaluation runs at 4Hz (every 0.25s), not every frame. Players don't teleport, so re-checking the closest player 60 times a second is just CPU I'm burning for no gain. Between re-evals, enemies keep chasing their last known target's live position. This becomes a meaningful win at higher enemy counts. If I pushed max to 100, target re-eval would still only run 4 times a second, not 100.

The "on platform" check is a 2D bounds test on X/Z (ignores Y since enemies float slightly above). If no player is on the platform, targetUserId stays nil and velocity stays zero, so enemies idle in place. Position clamping prevents enemies from drifting off the platform if chase math overshoots.

## Variation

Variation rolls once per enemy on spawn: color from a preset list, material from a preset list, scale between 0.8 and 1.4. The data is sent in the EnemySpawned event and every client constructs the same visual. That satisfies the "consistent across all clients" requirement without needing to re-sync it in snapshots.

I tied scale to a speed multiplier (2 minus scale, so range 0.6x to 1.2x) so variation feels mechanical instead of purely cosmetic. Small ones catch up to you faster, big ones lumber. Zero extra replication cost because scale is already in the spawn payload. The speed derivation happens locally on the server.

## Click handling

Every client-built Part stores its enemy ID as an Attribute and has a ClickDetector. On click, the client prints its side and fires a reliable remote to the server with the ID. Server validates the ID exists in its table and prints its own line. Same ID on both sides, spec requirement met.

## Admin UI

Built client-side as a ScreenGui. Two TextBoxes (spawn rate, cap) and a Kill All button. On FocusLost, the client fires a single AdminAction remote with an action name and value. Server validates and clamps (rate 0 to 10, cap 0 to 100) before applying. One remote handles all admin actions, which I found easier to extend than one remote per button.

## Things I scrapped or considered

**ECS / Matter.** My usual preference is a component-driven architecture, and the first instinct was to reach for it here. I deliberately didn't, because the job posting says the target codebase uses a one-script hierarchy. Shipping code that matches the studio's existing style reads better than shipping code that shows off a pattern they're not using.

**Per-enemy server scripts.** Considered, rejected immediately. Cheap to write but every enemy becomes its own scheduling unit, and you lose the single-iteration-per-frame property. Doesn't scale.

**Humanoid-based enemies.** The easy option. I'd have gotten pathfinding, animation, and damage for nearly free. But Humanoid replication is one of the heaviest things you can put on a server, and the scoring criteria is Recv at the cap. Hard pass.

**PathfindingService.** The spec says pathfinding is not required, and on a flat open 50x50 square it'd be overkill. Direct unit-vector chase is the right call.

**Batching EnemyRemoved for Kill All.** Considered sending one remote with a list of IDs instead of N separate remotes. Decided against it because at cap 20 it's instant, and a batched variant adds a code path I'd rather not ship without a reason to.

**Delta-encoded snapshots.** I could send only changed positions instead of the full enemy list each tick. Skipped because at 20 enemies the full-list cost is already tiny (162 bytes), and delta encoding introduces state-tracking complexity on both sides for marginal gain at this scale.

**Client-side prediction.** Enemies don't simulate forward between snapshots, they just lerp toward the last received position. At 15Hz that's ~66ms of latency to position updates, which is visually fine for "blob chases you" gameplay. At something like 5Hz I'd need prediction, but 15Hz is over the threshold where naive lerp holds up.

## Scalability note

The architecture should hold up past the 20-enemy cap without changes. Snapshot size scales linearly with enemy count (2 + 8N bytes). At 100 enemies that's 802 bytes per snapshot at 15Hz, about 12 KB/s, still well under what a real game's bandwidth budget tolerates. Server-side the main cost is the per-frame iteration of the enemy table and the targeting logic, both O(n), and kept thin on purpose.

## Testing process

Developed with Rojo serving a local baseplate. Incremental commits every feature or fix. Validated each phase before moving on: spawner before chase, chase before replication, replication before rendering. Snapshot packet sizes verified at 2 + 8N bytes at each count. Click-to-print verified IDs match between server and client.
