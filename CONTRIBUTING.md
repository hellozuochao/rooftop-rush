# Contributing / 参与贡献

Bug reports, documentation fixes and focused pull requests are welcome in Chinese or English. The maintainer reviews and merges changes and manages the official Roblox release. There is no guaranteed response schedule.

欢迎使用中文或英文报告问题、改进文档和提交 Pull Request。维护者负责审核合并与官方 Roblox 发布，不承诺固定回复时限。

1. Search existing Issues first. Discuss substantial gameplay or architecture changes before implementation.
2. Fork the repository and create a feature branch. Keep each PR focused on one change.
3. Edit `src/` and the build tools, not just generated Studio files. Register new production modules in `project.json`.
4. Run `python3 tools/verify.py --luau-bin /absolute/path/to/luau-bin`. For gameplay changes, also test in Studio and report which single-player, multiplayer and device scenarios were actually checked. Follow [RELEASING.md](RELEASING.md) for QA setup; never include QA scripts in production.
5. Describe the problem, final behavior and validation in your PR. Include screenshots for UI changes and identify untested behavior. Documentation-only changes need link/command review, not invented gameplay tests.
6. Resolve CI failures before merge. Do not change the license, add third-party assets or update dependencies without explaining the source and terms.

By submitting a contribution, you agree to license your contribution under the repository's MIT license and confirm you have the right to do so. Third-party resources must be disclosed in `THIRD_PARTY_NOTICES.md`; do not submit credentials, private player data or media without redistribution rights.

提交贡献即表示同意将该贡献按本仓库 MIT 许可提供，并确认有权这样做。第三方资源须注明来源与授权；不要提交凭证、私人玩家数据或无权分发的媒体。

Use respectful, specific feedback. A fork must publish to its own Roblox experience. Community PRs do not automatically deploy to the official game.
