# Rooftop Rush / 屋顶狂飙

A Roblox rooftop racing game with 12 course sections, solo NPC opponents, multiplayer rooms, jumping, sliding, stored items, continuous melee attacks and a free wardrobe.

[中文](README.md) · [Play on Roblox](https://www.roblox.com/games/116603842981489) · [Contribute](CONTRIBUTING.md)

## Run your own copy

1. Install Roblox Studio and Python 3. Clone this repository and enter its directory.
2. Run `python3 tools/build_place.py`. Only the Python standard library is needed to generate the place.
3. In Studio, open the generated `SkylineSample.rbxlx` and start a play test. Stop the test before editing. This file contains the complete place; `SkylineSample.rbxmx` is the import package.
4. For multiplayer validation, use Studio's local server/client testing with three clients. See [architecture](ARCHITECTURE.md) and [release procedure](RELEASING.md) for the separate QA package.
5. To publish a fork, create your own Roblox experience. Do not target the official game's PlaceId. Check [third-party asset requirements](THIRD_PARTY_NOTICES.md); asset availability and persistent storage can differ in your experience. Test cloud saves only in a separate test experience.

## Verify changes

Use the official [Luau 0.743 tools](https://github.com/luau-lang/luau/releases/tag/0.743), or build that tag using the commands in [.github/workflows/verify.yml](.github/workflows/verify.yml). Both `luau` and `luau-compile` must be in the directory passed below:

```sh
python3 tools/verify.py --luau-bin /absolute/path/to/luau-bin
```

This builds the place, checks the map and script manifest, compiles sources and runs pure-logic tests. Studio integration, live multiplayer, touch controls and device performance require separate testing. GitHub Actions runs offline checks and saves Studio build artifacts. Releases are reviewed separately; CI does not publish to Roblox.

## Source layout and versions

- `src/`: 27 production Luau scripts/modules.
- `project.json`: script types and installation paths.
- `tools/`: place and QA builders.
- `tests/`: logic, build and Studio integration checks.

Edit sources rather than generated Studio files. `main` is the maintained branch; `v23` and `v24` preserve historical game versions. See [changelog](CHANGELOG.md), [contribution guide](CONTRIBUTING.md) and [release procedure](RELEASING.md). There is no fixed release schedule.

## License

Project-owned code, build scripts and documentation are under [MIT](LICENSE). Third-party assets and Roblox platform components are excluded; see [notices](THIRD_PARTY_NOTICES.md). The license does not grant permission to impersonate the official project or imply endorsement. Historical tags predate the addition of the license file; use the current licensed source as the starting point for a fork.
