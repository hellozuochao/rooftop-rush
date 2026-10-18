# v25 本地候选版验证 — 2026-10-18

尚未发布 Roblox，也未创建 GitHub v25 Release。

## 已通过

- `python3 tools/verify.py --luau-bin /tmp/skyline-luau-0.743`：28 个生产脚本编译、40 项核心检查、构建源文件一致性、滑铲净空及非碰撞导向几何检查。
- 构建检查确认所有 14 种 ItemKey 均出现在补给中，无 SlideHint / SlideLabel 文字标牌，每个滑铲障碍具有图形提示。
- `python3 -m unittest discover -s tests -p '*release*.py'`：14 项发布工具测试通过。
- Roblox Studio 0.743 本地单人启动：CameraMode 为 LockFirstPerson；31 个本地补给模型成功生成。
- 在最终构建的 Studio 客户端检查全部 14 种道具模型：均生成部件，所有部件不碰撞且不参与查询。
- 在最终构建中检查四个朝向的前进、右移映射，共 8 项断言通过。日志：`V25_FINAL_PASS 14 item models; 8 directional checks Enum.CameraMode.LockFirstPerson 31`。
- 实际查看滑铲通道：无文字标牌，低开口、发光地面导向与滑铲图案可见；实际拾取弹簧并显示对应背包图标。发现图标与文本挤压后改为独立文本区域。

## 范围与后续检查

本轮未运行完整 12 段路线集成测试，未完成全部道具的多人实战验证及手机/手柄真机测试。更新了原路线测试的输入映射以适配第一视角，但不将其标记为已运行通过。最后一轮界面布局修复通过编译与构建检查。
