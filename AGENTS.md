# AGENTS.md

## 项目概况

- 项目类型：Godot 4.6 游戏项目。
- 项目名：`LudumGamejam`。
- 主场景：`res://scenes/opening/opening.tscn`。

## 目录约定

- `scenes/`：场景文件和场景相关脚本。
- `scripts/`：项目级共享脚本，例如游戏状态、关卡状态管理。
- `resources/`：`.tres` 资源，例如主题、配置资源等。
- `assets/`：图片、音频、字体、美术源文件等资源。
- `addons/`：Godot 插件。修改第三方插件前需要确认是否确实要改插件源码。

## 常用检查

- 在 Godot 4.6 编辑器中打开项目。
- 从主场景 `scenes/opening/opening.tscn` 运行项目。

## 任务完成标准

- 对配置类改动，复核相关配置文件内容。
- 对 Godot 场景、脚本、资源改动，尽量说明需要在编辑器中验证的入口和现象。
- 最终回复要简明列出已完成内容、涉及文件和后续建议。

## NOT TO DO 不要做

1. 不要运行 `godot --headless` 校验场景，直接告诉我你完成了。
