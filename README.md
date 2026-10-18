# 屋顶狂飙 / Rooftop Rush

Roblox 屋顶跑酷竞速：12 段赛道、单人 NPC 对手、多人房间、自由移动、跳跃与滑铲、储存道具、连续近战攻击、免费衣橱。

[在线游戏](https://www.roblox.com/games/116603842981489)

## 工程入口

- `src/`：27 个正式 Luau 脚本/模块。
- `project.json`：唯一安装清单，声明每个脚本的名称、类型和 Roblox 路径。
- `tools/build_place.py`：生成地图与可编辑 Studio 文件。
- `tests/`：纯逻辑、地图/安装清单检查和 Studio 集成测试。
- [架构说明](ARCHITECTURE.md)、[更新记录](CHANGELOG.md)、[发布流程](RELEASING.md)。

## 构建与检查

需要 Python 3 和官方 Luau 0.743 的 `luau`、`luau-compile`。

```sh
python3 tools/verify.py --luau-bin /path/to/luau-bin
```

生成 `SkylineSample.rbxlx`（完整工程）和 `SkylineSample.rbxmx`（导入包）。生成文件不提交 Git，CI 会保存构建产物。

```sh
python3 tools/build_qa.py
```

生成独立 Studio 测试包。测试脚本不能随游戏发布；具体流程见发布文档。

## 版本与协作

`main` 保存当前维护版本，功能改动使用分支，完成检查后合并。`v23` 是已验证的历史基线；之后使用版本标签定位、回退和分支开发。

```sh
git switch -c feature/my-change
# 基于历史版本开发，不破坏当前主线：
git switch -c experiment/from-v23 v23
```

GitHub 私有仓库：[hellozuochao/rooftop-rush](https://github.com/hellozuochao/rooftop-rush)。本地 `main` 已关联 `origin/main`，`v23` 和 `v24` 历史标签已上传。初始导入提交由自动化身份 Codex <codex@localhost> 标记，没有设置或修改全局 Git 身份。

音乐来自 Roblox Creator Store 的 APM Music：[Spirit Warmth](https://create.roblox.com/store/asset/9042295159)。工程只引用音频资产，不分发音频文件。其他素材的使用仍须遵循各自许可。
