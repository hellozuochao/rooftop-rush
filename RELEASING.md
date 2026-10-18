# 版本与双平台发布

## 版本的唯一来源

根目录 `VERSION` 是唯一游戏版本号，下一候选版本为 `v25`；它不是已上线声明。
构建器把版本和 Git 提交 SHA 写入 `ReplicatedStorage/BuildInfo`。服务端补充实际
`game.PlaceVersion`，设置面板显示游戏版本与当前服务器的 Roblox 平台版本。
Roblox 平台版本由 Roblox 分配，不要求数字等于 v25。已有 v23、v24 标签保持不变。

每个新版本增加 `VERSION`，并编写 `releases/<版本>.md`。日常修改和 PR 运行验证；
完成一批修改并通过 Studio 验证后，维护者触发一次正式发布。GitHub 与 Roblox
不能原子地同时提交，因此只有带发布回执的公开 Release 才表示双平台流程完成。

## 一次性配置（维护者）

在 GitHub 仓库 Settings → Environments 创建 `roblox-production`，限制仅允许
`main` 分支部署。需要审批时可配置 required reviewers；不要给社区 PR 发布凭证。

在该 Environment 配置：

| 类型 | 名称 | 内容 |
| --- | --- | --- |
| Secret | `ROBLOX_API_KEY` | Roblox Creator Dashboard 创建的发布 API key |
| Variable | `ROBLOX_UNIVERSE_ID` | 本游戏的 Universe ID |
| Variable | `ROBLOX_PLACE_ID` | 官方 Place ID：`116603842981489` |

派生项目必须配置自己的体验与 Place，不能使用官方目标。
API key 仅授予目标游戏所需的 `universe-places` Write 权限；按 Roblox 的界面配置
有效期与网络访问条件。不要将密钥写进源码、提交、日志或聊天，也不要为了 CI
开放无关游戏或存档权限。[官方发布接口与授权说明](https://create.roblox.com/docs/cloud/guides/usage-place-publishing)。
密钥必须由账号持有者创建后直接粘贴到 GitHub Environment Secret。到期时在同一
Secret 中替换。代码只从环境变量读取，不打印密钥或 Roblox 的错误响应体。

## 每次正式发布

1. 从 `main` 建功能分支，修改源码与构建器；新增模块登记 `project.json`。
2. 设置新的 `VERSION` 并编写对应更新说明；已发布的标签、文件与回执不覆盖。
3. 运行：
   ```sh
   python3 -m unittest discover -s tests -p 'test_release.py'
   python3 tools/verify.py --luau-bin /absolute/path/to/luau-bin
   ```
4. 对最终提交在 Studio 测试。`tools/build_qa.py` 生成独立 QA 包，服务端测试移至
   ServerScriptService，客户端测试移至 StarterPlayerScripts。Workspace.QAMode
   设 Solo 验证单人，设 Multi 配合三个客户端验证多人。测试完移除 QA 实例与属性。
   验证设置中的版本号、手机横竖屏与 iPad、玩法说明、道具、移动/攻击/碰撞、NPC、
   准备与观战。真实触屏、网络和音频要单独验证，不能声称离线 CI 覆盖它们。
5. 合并最终提交。打开 Actions → **Publish game version** → **Run workflow**，
   选择 `main`，填写与该提交 `VERSION` 一致的版本号；确认该提交已通过 Studio
   测试，正常发布的 `recovery_version` 保持 `0`，`source_commit` 留空。
6. 流程重新验证、构建一次，再把同一份构建交给发布作业。它固定 Git 标签、创建
   GitHub 草稿和构建附件，持久保存“准备上传”状态后才调用 Roblox Published 接口。
7. Roblox 成功返回平台版本后，流程保存回执，再公开 GitHub Release。Release
   包含 `.rbxlx`、`.rbxmx`、源码标签、更新说明和 `release-state.json`；回执记录
   游戏版本、完整提交 SHA、目标 Universe/Place、两个文件 SHA-256 和 Roblox 版本。
8. 进入新服务器检查显示的游戏版本与回执对应。旧服务器继续运行旧版本，流程不会
   自动踢出玩家或重启服务器；紧急更新时另行决定服务器迁移/重启。

直接在 Studio 发布会绕过这套同步记录。正式更新应走该流程；紧急手动发布后必须
核对实际源码与构建并补记，而不能把未知线上内容标记成某个 Git 版本。
新模块未同步、导入包缺少 BuildInfo 或旧 Studio 工程混入脚本都可能造成运行差异；
推荐打开该次完整 `.rbxlx` 验证。手动导入包时将 BuildInfo 放回 ReplicatedStorage。

## 失败与恢复

- 验证或凭证配置失败：不会请求 Roblox，修复后重新运行。
- 尚未尝试 Roblox 上传的草稿：原提交重跑可补齐附件，再尝试一次上传。
- 已保存 Roblox 版本回执但 GitHub 最终发布失败：在原 Actions 运行中选择重跑，
  将跳过 Roblox 上传，只补完 GitHub 发布。
- Roblox 上传超时、进程中断、回执持久保存失败：远端可能已经发布，因此流程停在
  `attempted`，绝不自动重复 POST。不要删除草稿、状态附件或版本标签来绕过保护。
- 恢复时先在 Roblox 版本历史及新服务器核对：目标 Place、游戏版本、构建提交 SHA
  和具体平台版本。确认确实是此构建后，从 `main` 重新触发工作流，在 `source_commit` 填入原回执中的完整提交 SHA，填入核实的
  `recovery_version`；流程记录人工恢复依据并只完成 GitHub 发布。即使 `main` 已前进也使用原 SHA，工作流会验证该提交属于 main 历史并构建原提交。
  普通“重跑”不能改变原输入。
  未能核实则保持草稿并调查，不猜版本号。
- 已公开且身份一致的 Release 重跑不会再发布；不同提交、目标或校验值直接拒绝。

GitHub 的状态附件替换如果中途失败可能造成状态附件缺失，此时必须人工核实，脚本
不会自行猜测状态。恢复输入由维护者对照平台核验，不能代替线上检查。

## 回退

从已验证的历史版本创建修复分支，更新为新的版本号，完成测试后重新发布。
不要移动旧标签或覆盖旧 Release。通过 Roblox 控制台紧急恢复也必须补充对应
版本记录；旧服务器的迁移另行安排。官方维护沿用原 Place，派生项目使用自己的体验。

## 当前验证边界

发布状态机和接口契约使用模拟测试；离线验证包含源码编译、地图与清单检查、纯逻辑。
真正的 Roblox API 发布、Studio UI 和新服务器回执需要配置发布凭证后执行，准备代码
本身不代表 v25 已上线。素材授权见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
