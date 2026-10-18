# 维护与发布流程

1. 从 `main` 建分支，修改 `src/` 和地图生成器；新增模块必须登记到 `project.json`。
2. 执行 `tools/verify.py`，确认编译、纯逻辑和地图/安装清单检查通过。
3. 执行 `tools/build_qa.py`，在 Studio 测试副本导入 QA 包。服务端脚本放入 ServerScriptService，客户端脚本放入 StarterPlayerScripts。Workspace 的 QAMode 设为 Solo 或 Multi；多人测试使用 3 个客户端。
4. 验证手机横竖屏、iPad、安全区、设置/说明、道具布局、滑铲、攻击与碰撞、NPC 完赛、准备/观战流程。音频试听及真实触屏需要实际设备验证；CI 不声称覆盖这些。
5. 写该版本测试报告，注明未验证项。正式工程移除所有 QA 脚本/实例和 QAMode 属性；确认 27 个生产脚本内容及安装路径与清单一致。
6. 保存版本快照；从原游戏工程发布到 Roblox，确认 PlaceId 为 116603842981489，检查 PublishSuccessful。生成文件单独打开不带原游戏发布身份，不要误建新体验。
7. 提交代码与测试报告，打版本标签。推送标签会运行 CI 并生成含 Studio 构建文件的 GitHub **草稿** Release，审阅后再公开 Release。

GitHub CI 已接通；每次运行的结果见仓库 Actions 页面，只有实际通过的检查可计入对应版本的验证结果。CI 不包含 Roblox 凭证，也不会自动替换线上体验。

## 回退

优先在新分支从历史标签构建，验证后重新发布到同一 Roblox Place；也可使用 Creator Dashboard 的历史版本恢复。Git 标签保存代码状态，Roblox 发布版本保存线上状态，二者需在测试报告中对应记录。

## GitHub 连接

私有仓库为 `https://github.com/hellozuochao/rooftop-rush`，本地 `origin` 已连接，`main`、`v23` 和 `v24` 已上传。保持源代码私有，不影响 Roblox 游戏公开游玩。后续提交通过 `git push` 上传；新版本标签通过 `git push origin <标签>` 上传。不要在源码、日志或 workflow 中写入账号密码、Cookie 或访问令牌。
