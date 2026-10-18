# 屋顶狂飙 / Rooftop Rush

Roblox 屋顶跑酷竞速：12 段赛道、单人 NPC 对手、多人房间、自由移动、跳跃与滑铲、储存道具、连续近战攻击、免费衣橱。

[在线游戏](https://www.roblox.com/games/116603842981489) · [English](README.en.md) · [贡献指南](CONTRIBUTING.md)

## 工程入口

- `src/`：27 个正式 Luau 脚本/模块。
- `project.json`：唯一安装清单，声明每个脚本的名称、类型和 Roblox 路径。
- `tools/build_place.py`：生成地图与可编辑 Studio 文件。
- `tests/`：纯逻辑、地图/安装清单检查和 Studio 集成测试。
- [架构说明](ARCHITECTURE.md)、[更新记录](CHANGELOG.md)、[发布流程](RELEASING.md)。

## 运行自己的游戏副本

1. 安装 Roblox Studio 和 Python 3，下载或克隆本仓库，进入项目目录。
2. 运行 `python3 tools/build_place.py`。生成场景只依赖 Python 标准库。
3. 在 Studio 中打开生成的 `SkylineSample.rbxlx`，启动游戏测试；修改前先停止测试。该文件是完整场景，`.rbxmx` 是导入包。
4. 多人验证使用 Studio 本地服务器与三个客户端；独立 QA 包的用法见[架构说明](ARCHITECTURE.md)和[发布流程](RELEASING.md)。
5. 发布自己的版本时创建自己的 Roblox 体验，不要使用官方游戏的 PlaceId。先核对[素材权限与替换说明](THIRD_PARTY_NOTICES.md)。云存档在隔离测试体验中验证，素材可用性和存档行为可能因体验权限而异。

## 构建与检查

需要 Python 3 和[官方 Luau 0.743](https://github.com/luau-lang/luau/releases/tag/0.743) 的 `luau`、`luau-compile`。可下载对应系统工具，或按 [CI 中的命令](.github/workflows/verify.yml) 编译该版本。将下方参数替换成两个可执行文件所在目录的绝对路径。

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

GitHub 仓库：[hellozuochao/rooftop-rush](https://github.com/hellozuochao/rooftop-rush)。本地 `main` 已关联 `origin/main`，`v23` 和 `v24` 历史标签已上传。初始导入提交由自动化身份 Codex <codex@localhost> 标记，没有设置或修改全局 Git 身份。

音乐来自 Roblox Creator Store 的 APM Music：[Spirit Warmth](https://create.roblox.com/store/asset/9042295159)。工程只引用音频资产，不分发音频文件。其他素材的使用仍须遵循各自许可。

## 许可证与长期维护

本项目自有代码、构建脚本和文档采用 [MIT 许可证](LICENSE)，允许在遵守许可声明要求的情况下修改、分发和商用。第三方音乐、Roblox 内置素材及角色资源不属于本项目的 MIT 授权范围，详见[第三方素材说明](THIRD_PARTY_NOTICES.md)。该许可不授予冒充官方项目或暗示官方背书的权利。历史标签早于 LICENSE 文件的加入；建议从当前已包含许可的源码开始派生项目。

通过 Issues 提交问题和建议，通过 Pull Request 贡献修改。维护者审核合并并负责官方 Roblox 发布；自动检查不代替 Studio 与真机验证。稳定版本附更新说明与经审核的构建文件，不承诺固定发布周期。请阅读[贡献指南](CONTRIBUTING.md)。
