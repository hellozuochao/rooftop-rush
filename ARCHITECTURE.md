# 屋顶狂飙：工程维护说明

## 源码与构建

`src/` 是源码依据，`project.json` 明确每份脚本的 Roblox 类型及安装位置。`tools/build_place.py` 生成完整场景 `SkylineSample.rbxlx` 和更新模型 `SkylineSample.rbxmx`。不要只改生成文件，否则下次构建会覆盖修改。新模块必须加入清单；测试会拒绝遗漏、重复名称或源码与场景不一致。

## 模块职责

- `Game.server` → `CourseProgress`：检查点、死亡、碰撞掉落恢复、碰撞分组。
- `Race.server` → `RaceRoom`：房主、准备、倒计时、开局、观战、结算。
- `Systems.server` → `GameplaySystems`：组装服务，持有角色状态、外观存档、远程请求和更新循环。
- `CollisionService`：碰撞体、动量反馈、击退；`CombatService`：近战距离、方向、冷却和命中。
- `InventoryService`：背包增删和属性同步；`ItemService`：道具效果、陷阱、清理。
- `NpcService`：NPC 创建、导航、动作选择和清理；`CourseRewards`：补给、金币及路线奖励。
- `WardrobeService`：角色外观应用。
- `Hud.client`：输入、移动、玩家动作；`CameraController`：唯一镜头逻辑。
- `Race.client`：房间界面；`Systems.client`：玩法界面组装。
- `InventoryUI`：实际持有道具的滚动列表；`WardrobeUI`：免费外观界面；`NpcAnimator`：玩家和 NPC 的近战动作叠加。
- `shared/MovementMath`：不依赖 Roblox 实例的移动数学与槽位校验；`shared/Rules`：背包、补给、近战的公共规则。

服务工厂通过参数接收角色查询、时钟、通知等依赖，避免互相 require 形成循环。仅入口调用 Start；模块加载时不自行注册更新循环。GameplaySystems.Get 是内部集成测试入口，不是客户端远程接口。

## 数据与权威

房间阶段保存在 ReplicatedStorage 的房间状态，角色公开表现通过 Attributes 同步。实际背包和运行状态由服务端持有。客户端发送意图，服务端验证当前比赛状态、冷却、目标与参数后执行；不要让客户端直接指定伤害或领奖结果。纯数学模块可在客户端和服务端复用。外观 DataStore 名称保持原值，避免重构丢失玩家选择。

## 常见扩展

增加道具：在 Config 加元数据，在 ItemService 实现效果，复用 CollisionService 的击退，补充 Suite.server 测试及无目标/护盾等边界。InventoryUI 根据实际背包生成按钮，无需添加空槽。

增加外观：修改 Config 和 WardrobeService，保持原编号稳定；客户端列表自动读取配置。新增关卡仍在 build_place.py 中生成，同时更新检查点、路线几何测试；当前地图生成器暂未进一步拆分成关卡资产包。

修改移动：MovementMath 负责加速/减速，Hud 负责输入与角色执行；NPC 导航在 NpcService。先跑不同帧率的纯逻辑回归，再做 Studio 障碍、滑铲和碰撞测试。

## 验证方式

在项目目录运行：

```sh
python3 tools/verify.py --luau-bin /tmp/skyline-luau-0.743
```

参数指向本机官方 Luau 工具目录。该命令构建场景，检查几何及清单源码一致性，编译全部源码和测试，运行纯逻辑测试。它不等同于联机测试。

`tools/build_qa.py` 单独生成 `tests/QAV23.rbxmx`。仅在 Studio 导入，将 QAV23Server 移到 ServerScriptService，QAV23Client 移到 StarterPlayerScripts。Workspace.QAMode 设 Solo 跑道具、外观、界面、12 关和 NPC；设 Multi 并启动 3 个客户端跑房间和玩家交互。结果输出 V23_*_PASS / FAIL。自动路线使用真实移动输入但不代表每条支路和真人手感已验证。

发布前必须移除 QA 脚本和 QAMode 属性，确认正式场景仅含 project.json 所列源码。测试脚本不能进入生产环境。手机/iPad 模拟器只能验证布局和模拟操作，真实触屏、网络延迟、低端设备性能仍需真机验证。

## 回退与限制

v21 源码保存在 backup-v21，完整已验证场景在 SkylineV21Verified.rbxlx。回退时同时恢复源码、清单和构建工具，不能只替换某个入口。发布目标沿用原 Place，不创建新体验。本次保留原远程消息名与 Attributes，降低迁移风险。

此目录尚未使用 Git；这些备份不是无限历史版本。后续建议建立 Git 仓库并按可发布版本打标签。当前外观存档适配和部分输入/动画逻辑仍在组装层，可随下一次具体功能继续拆分，避免一次性改动过多。

设备模拟可通过 StudioDeviceSimulatorService 设置预设和方向，测试时可用 FitToWindow 完整查看画面。官方接口参考：https://create.roblox.com/docs/reference/engine/classes/StudioDeviceSimulatorService 。当前验证使用 iPhone XR 横屏、iPad 第六代横屏/竖屏。测试环境云 API 关闭；如果开启云存档测试，请先使用隔离测试体验，避免回归测试改动正式玩家存档。

## v23 界面、声音与 NPC

`Modal` 独占管理 PlayerGui.ActivePanel（Room / Wardrobe / Settings / 空），移动输入和各 HUD 都读取该状态。不得再在独立 ScreenGui 上绕过它打开面板。`SettingsUI` 提供音乐、音效音量和按钮大小/透明度，设置保留到本次客户端会话结束。

`AudioController` 分离 RaceMusic / RaceSFX SoundGroup。背景音乐使用 Roblox Creator Store 的 APM Music《Chaser》（9042664292），适用于游戏内城市电子竞速；来源：https://create.roblox.com/store/asset/9042664292/Chaser 。动作音效使用 Roblox 内置 sounds 资源。电脑系统静音设置保持不变。

`ItemVisuals` 只生成客户端补给外观：悬浮球、轨道粒子、光效，不修改服务端拾取中心和冷却逻辑；110 studs 外关闭动画与发射器，避免整条赛道持续渲染全部粒子。ItemService 的追踪弹带拖尾，地面技能使用圆形场。

NPC 从参赛者角色克隆相同骨架，移除脚本/旧碰撞体，再应用同一衣橱服务。其 Animator 使用克隆人物 Animate 下的 idle/walk/run/jump/fall 动画；滑铲复用 Hud 的其他角色姿态叠加。移动加速使用共享 MovementMath，转身使用与玩家相同的指数插值。NPC 导航仍由难度控制，不能把视觉统一等同于真人级 AI。

准备区包含客户端方向限制、服务端位置边界和可见侧栏。倒计时开始只定位一次，NPC 在倒计时创建并活动；比赛开始才获得 Running 和道具权限。独立 Sprint 远程分支及按钮已删除，Boost/Magnet 道具仍可临时提高速度。
