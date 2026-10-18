# 本地测试、Studio 发布与 GitHub 版本同步

当前采用本地 Roblox Studio 测试和发布，不使用 GitHub 云端发布 Roblox，
也不需要 Roblox Open Cloud API key。GitHub 自动工作流仅构建和验证代码。

## 统一版本

根目录 `VERSION` 是游戏版本号。正式发布状态以同名 GitHub Release 的回执为准。
构建将版本和完整 Git 提交 SHA 写入 `ReplicatedStorage/BuildInfo`；服务端补充
实际 `game.PlaceVersion`，设置面板显示游戏版本与当前服务器的 Roblox 平台版本。
平台版本由 Roblox 分配，通过发布记录与 GitHub 标签对应，不强求数字相同。
v23、v24 历史标签保持不变，不追填未经核实的平台版本。

## 每次修改与发布

1. 在本地分支修改源码、地图和界面；需要正式发布时更新 `VERSION` 与
   `releases/<版本>.md`。已发布标签不移动、不覆盖。
2. 执行离线检查：
   ```sh
   python3 tools/verify.py --luau-bin /absolute/path/to/luau-bin
   ```
   新生产模块须登记 `project.json`。修改生成的 Studio 文件不能替代修改源码。
3. 在 Studio 本地试玩。集成测试运行 `python3 tools/build_qa.py --place Solo`，
   打开生成的 `tests/QAV25Solo.rbxlx` 本地试玩；多人使用 `--place Multi`
   生成 `tests/QAV25Multi.rbxlx`，启动三个客户端验证。
   这些独立测试文件自动安装 QA 脚本并选择模式，禁止发布。正式构建不得包含 QA 脚本或 QAMode。
   按改动验证移动、道具、碰撞、NPC、准备/观战、版本显示和手机/iPad 布局。
   音频、真实触屏和设备性能需单独验证，如未测必须注明。
4. 将最终源码、版本号和说明提交并推送 GitHub，等待自动检查通过。记录完整提交
   SHA。以该提交的干净工作区重新构建；核对 BuildInfo.Version 和 BuildInfo.Commit，
   对这个最终文件进行 Studio 发布前检查。测试发现问题则修复并重新提交、构建。
5. 冻结这次构建文件并计算 SHA-256。使用已登录的本地 Studio 打开完整
   `SkylineSample.rbxlx`，确认待发布内容和目标体验，通过 Studio 发布到已有官方
   Place `116603842981489`（Universe `10771400448`）。生成文件本身不携带原体验
   的发布身份，必须明确选择已有目标，不能误建新游戏或覆盖别的 Place。
   若 Studio 内又修改了内容，先把修改回写源码、重新提交和验证，不能发布与标签不符的文件。
6. 确认 Studio 报告发布成功，并从 Roblox 版本历史和新服务器核实实际平台版本。
   在新服务器核对游戏版本、PlaceId、BuildInfo.Commit 与该次提交一致。
   旧服务器可能仍运行旧版本；重启或迁移玩家另行决定。
7. 用核实的结果填写 `release-state.json`（模板见下），记录测试范围与未测项。
   在已验证的源码提交上创建同名 Git 标签（例如 v25），推送标签。
   GitHub Release 先建草稿，附同一份 `.rbxlx`、`.rbxmx`、回执和更新说明；
   核对文件校验值后公开 Release，表示本次双平台发布完成。

普通代码提交不等于游戏发布。每次完成一批修改并验证通过后进行一次正式发布。
GitHub Release 与 Roblox 发布不能原子地同时完成，因此允许短暂不同步，但不得
在 Roblox 尚未确认成功时把 Release 标记为已上线。

## 发布回执

以下是字段模板，尖括号必须替换为实际核实结果；不要把占位符当成已发布证据。
回执作为 Release 附件保存，避免为补记平台版本而移动源码标签。

```json
{
  "method": "local-studio",
  "version": "<游戏版本>",
  "commit": "<完整源码提交 SHA>",
  "universe_id": 10771400448,
  "place_id": 116603842981489,
  "roblox_version": "<实际核实的平台版本号>",
  "published_at": "<UTC 发布时间>",
  "sha256": {
    "SkylineSample.rbxlx": "<SHA-256>",
    "SkylineSample.rbxmx": "<SHA-256>"
  },
  "verification": "<Studio 发布成功与新服务器核对结果>"
}
```

## 失败与回退

- Studio 发布失败或结果不明：先核查版本历史和新服务器，不盲目重发，不公开 Release。
- Roblox 成功、GitHub 同步失败：保留原构建、提交和平台版本，只补完 GitHub 标签与
  Release，不重复发布 Roblox。重试前检查已有标签/草稿，不覆盖不同提交的同名版本。
- 已发布的游戏有问题：从历史版本创建修复分支，用新版本号重新验证和发布，不移动旧标签。
- Roblox 控制台紧急回退也须补记实际版本对应关系，不能猜测线上内容属于哪个提交。

## 暂停的云端方案

原发布工作流已移至 `tools/optional-cloud/publish.yml`，不在 `.github/workflows/`
目录中，GitHub 发布入口已停用。`tools/release.py` 和恢复测试作为备用实现保留，
不是当前本地发布步骤。`roblox-production` 环境中的目标 ID 保留，当前不需要配置
`ROBLOX_API_KEY`。以后启用云端方案需重新确认、恢复工作流并配置凭证。

派生项目必须发布到自己的 Roblox 体验。素材授权见
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
