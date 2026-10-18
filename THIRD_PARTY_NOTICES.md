# Third-party assets / 第三方素材

The MIT license covers this project's own source code, build scripts and documentation. It does not relicense Roblox, Roblox Studio, third-party media, or avatar assets loaded by the platform. Generated Studio files contain code, generated geometry and asset references; they do not grant rights to the referenced media.

MIT 适用于本项目自有源码、构建脚本和文档，不覆盖 Roblox 平台、Studio、第三方媒体或平台加载的角色素材。生成的 Studio 文件不改变其引用资源的授权。

| Resource / 资源 | Reference / 来源 | Use / 用途 |
| --- | --- | --- |
| Spirit Warmth — APM Music | [Creator Store, 9042295159](https://create.roblox.com/store/asset/9042295159) | Background music referenced in `src/client/AudioController.luau`; no audio file is included. |
| Roblox built-in sounds | `rbxasset://sounds/volume_slider.ogg`, `action_get_up.mp3`, `impact_water.mp3`, `action_footsteps_plastic.mp3` | Gameplay cues referenced in `AudioController.luau`; supplied by Roblox. |
| Roblox built-in particle texture | `rbxasset://textures/particles/sparkles_main.dds` | Referenced in `ItemVisuals.luau` and `ItemService.luau`; supplied by Roblox. |
| Player avatar appearance and animations | Loaded at runtime through Roblox; NPCs reuse player character rigs and animations | Availability and rights depend on the relevant Roblox assets. No avatar media is bundled here. |
| Luau 0.743 | [Official Luau source](https://github.com/luau-lang/luau/tree/0.743) | External build/test tool, downloaded separately by CI; its own license applies. |

Asset access may differ between experiences. Verify the relevant permissions before publishing a fork. For the background music, replace the asset ID in `src/client/AudioController.luau` with an audio asset you are permitted to use and rebuild; setting music volume to zero silences playback but is not a license grant. Do not redistribute the referenced audio or texture files under this project's MIT license.

素材在其他体验中的可用性可能不同。发布自己的版本前请核对资源权限；背景音乐可以替换为自己有权使用的音频 ID 后重新构建。不要以本项目 MIT 许可分发第三方音乐或贴图文件。

References: [Roblox audio assets](https://create.roblox.com/docs/audio/assets), [Creator Store](https://create.roblox.com/docs/production/creator-store).
