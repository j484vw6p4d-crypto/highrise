# Highrise

Black-tie murder on the 80th floor.

A finished Murder Mystery round game: rain on glass, marble hall, gold revolver, silent knife. Matches the loop that keeps Murder Mystery 2 in Roblox’s live top five, with a luxury penthouse instead of a cartoon map.

## Loop

1. **Lobby** — terrace shop, bots fill the guest list to 6.
2. **Reveal** — you are Murderer, Sheriff, or Innocent.
3. **Round (2:00)**
   - Murderer: click to knife (close range).
   - Sheriff: click to fire the gold revolver (one shot, slow reload). Shooting an innocent kills you.
   - Innocents: survive, finish tasks (guest book, wine, piano, fuse, vault). If the sheriff falls, anyone can pick up the revolver.
4. **Payout** — coins for wins, kills, tasks, surviving. Then the next night.

Play Solo in Studio works. Bots wander, hunt, and flee.

## Studio

New Baseplate (or a new experience). Rojo Connect. Accept. Play.

Game Settings → Security → **Enable Studio Access to API Services** (DataStores).

## Robux

Creator Dashboard → the Highrise experience → **Monetization**.

Create these developer products and game passes, then paste the IDs into `src/ReplicatedStorage/Shared/Config.lua`. Leave `id = 0` to grant in Studio so you can test the shop without live IDs.

| Kind | Name | Price |
| --- | --- | --- |
| Product | 800 Coins | 79 |
| Product | 4,500 Coins | 399 |
| Product | 12,000 Coins | 799 |
| Pass | VIP | 399 |
| Pass | Double Coins | 199 |
| Pass | Sheriff Luck | 249 |

VIP: 2× coins, gold nametag, Gilded tuxedo. Sheriff Luck: +35% sheriff chance.

## Controls

WASD · mouse look · click/tap to attack · ProximityPrompt on tasks · Shop button for cosmetics and Robux.

## Stack

Rojo 7.7 · Rokit · Luau. World is built in `Services/World.lua` (no .rbxl in git).
