# Path of the Ancients

Path of the Ancients is a Dota 2 custom game project. The repository mirrors Dota's two addon roots:

```text
content/  Workshop authoring sources: maps, Panorama, materials and particles
game/     Runtime sources: addon metadata, Lua, NPC KV and localization
```

Generated runtime resources such as map VPKs and compiled `*_c` files are intentionally ignored.

## Local setup

Close Dota and any addon watcher, then link both project roots into an installed Dota tree:

```bash
./setup_dota_links.sh "/path/to/dota 2 beta"
```

The script creates only these addon links:

```text
content/dota_addons/labyrinth_of_the_ancients -> repository content/
game/dota_addons/labyrinth_of_the_ancients    -> repository game/
```

On Windows, enable Developer Mode or open Command Prompt as Administrator, then run:

```bat
setup_dota_links.bat "C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta"
```

The batch file creates the same two directory symlinks and refuses to replace an existing addon path.

The reusable compiler and watcher are documented separately in `~/Documents/dota 2 beta/COMPILING_ADDONS.md` on the current development machine.
