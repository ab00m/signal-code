# 全局配置索引

本文档用于快速定位项目中常用玩法参数的配置位置。当前项目还没有统一的 `RunConfig` 或 `LevelConfig` 资源，战斗参数分散在场景、脚本常量和 `.tres` 数据资源中。

## 战斗关卡入口

- 主战斗场景：`scenes/game_scene/levels/survival_arena.tscn`
- 主战斗脚本：`scenes/game_scene/levels/survival_arena.gd`
- 当前战斗使用的普通敌人配置：`resources/enemies/enemy_normal_signal.tres`
- 当前战斗使用的 Boss 配置：`resources/enemies/enemy_boss_signal.tres`
- 当前战斗使用的默认法杖：`resources/spells/wands/combat_default_wand.tres`
- 当前战斗使用的法术数据库：`resources/spells/spell_card_database.tres`

## 关卡节奏

位置：`scenes/game_scene/levels/survival_arena.gd`

- `WAVE_DEFS`：每波敌人数和出怪间隔。
  - `count`：该波生成多少只普通敌人。
  - `interval`：同一波中每只敌人之间的生成间隔。
- `start_delay`：战斗开始前等待时间，可在场景 Inspector 中覆盖。
- `wave_pause`：每波清完后的等待时间，可在场景 Inspector 中覆盖。
- `player_left_margin`：玩家在屏幕左侧的布局位置。
- `boss_right_margin`：Boss 出现锚点距离屏幕右侧的位置。

当前流程是：按 `WAVE_DEFS` 逐波刷普通敌人，全部波次清完后生成 Boss。

## 玩家初始数据

主要位置：

- `scenes/game_scene/levels/survival_arena.tscn`
- `scripts/player/player.gd`

当前战斗场景中 `Player` 节点覆盖了：

- `max_hp = 5`
- `cast_cooldown = 0.28`

脚本默认值在 `scripts/player/player.gd`：

- `max_hp = 3`
- `cast_cooldown = 0.35`
- `hurt_invincible_duration = 0.5`
- `idle_cast_direction = Vector2.RIGHT`

初始金币当前来自 `Player.reset_player()`：

- `current_gold = 0`
- `current_xp = 0`
- `current_hp = get_effective_max_hp()`

商店打开时会读取 `player.current_gold`，关闭商店时再把商店剩余金币写回玩家。

## 战斗商店初始状态

位置：`scenes/game_scene/levels/survival_arena.gd` 的 `_configure_shop_state()`

当前战斗商店初始化：

- `shop_run_state.gold = player.current_gold`
- `shop_run_state.inventory_capacity = 6`
- `shop_run_state.spell_slot_count = 6`
- `shop_run_state.inventory_spell_entries = []`
- `shop_run_state.loadout_spell_entries` 从当前 `wand_runtime.wand_data` 转换而来。

商店运行时数据类型：`scripts/runtime/run_state.gd`

- `gold`：商店金币。
- `inventory_spell_entries`：背包法术。
- `loadout_spell_entries`：施法栏法术。
- `inventory_capacity`：背包容量。
- `spell_slot_count`：施法栏数量。
- `current_wave`：购买记录用的当前波次。
- `spell_database`：法术数据库。

商店规则位置：`scripts/shop/shop_service.gd`

- `SHOP_OFFER_COUNT = 4`：每次商店展示的商品数。
- `SHOP_BASE_REFRESH_COST = 2`：刷新费用。
- 商品价格来自法术卡牌资源的 `buy_cost`。
- 商品是否出现由法术卡牌的 `can_appear_in_shop` 和 `shop_weight` 控制。
- 拥有上限由法术卡牌的 `max_owned_count` 控制。

## 法杖和初始法术

默认战斗法杖：`resources/spells/wands/combat_default_wand.tres`

字段来自：`scripts/spell/data/wand_data.gd`

- `deck`：初始牌组。
- `draws_per_cast`：每次施法抽取多少张主动作。
- `cast_delay`：法杖施法延迟。
- `recharge_time`：法杖回充时间。
- `mana_max`：最大法力。
- `mana_recharge_per_second`：每秒回蓝。
- `shuffle_each_cycle`：循环时是否洗牌。

当前 `combat_default_wand.tres` 初始只有 `signal_bolt`。

## 法术卡牌

法术数据库：`resources/spells/spell_card_database.tres`

新增法术卡后，需要把卡牌资源加入这个数据库，否则商店和运行时查询不到。

卡牌资源目录：`resources/spells/cards/`

基础字段来自：`scripts/spell/data/spell_card_data.gd`

- `id`：法术唯一 ID。
- `display_name`：显示名。
- `description`：描述。
- `mana_cost`：耗蓝。
- `rarity`：稀有度。
- `category`：分类。
- `buy_cost`：商店价格。
- `shop_weight`：商店出现权重。
- `can_appear_in_shop`：是否进入商店池。
- `max_owned_count`：最多拥有数量，`-1` 表示无限制。

动作卡字段来自：`scripts/spell/data/action_card_data.gd`

- `damage`、`knockback_force`、`speed`、`lifetime`、`radius`
- `projectile_count`、`spread_degrees`、`pierce`、`bounce`
- `explosion_radius`、`projectile_color`、`on_hit_effects`

修饰卡字段来自：`scripts/spell/data/modifier_card_data.gd`

- `modifier_type`
- `value_float`
- `value_int`

触发动作卡字段来自：`scripts/spell/data/trigger_action_card_data.gd`

- `trigger_mode`
- `timer_delay`
- `payload_action_count`

## 敌人数据

敌人数据资源目录：`resources/enemies/`

当前已有：

- `enemy_normal_signal.tres`：普通信号体，当前战斗普通波次使用。
- `enemy_boss_signal.tres`：Boss 信号核，当前战斗 Boss 使用。
- `enemy_elite_signal.tres`：精英信号体，目前资源存在，但 `survival_arena.gd` 当前没有接入精英刷怪流程。

字段定义：`scripts/combat/enemies/enemy_config.gd`

- `enemy_id`：敌人 ID。
- `display_name`：显示名。
- `enemy_type`：敌人类型。
- `max_hp`：生命值。
- `move_speed`：移动速度。
- `collision_radius`：碰撞半径。
- `separation_radius`：敌人分离半径。
- `separation_strength`：敌人分离力度。
- `knockback_multiplier`：击退倍率。
- `hit_flash_duration`：受击闪烁时长。
- `hit_flash_intensity`：受击闪烁强度。
- `guaranteed_xp_drop`：固定经验掉落。
- `gold_drop_chance`：金币掉落概率。
- `gold_drop_amount_min`：金币最小掉落。
- `gold_drop_amount_max`：金币最大掉落。
- `body_scene`：敌人视觉场景。
- `body_color`：身体颜色。
- `outline_color`：描边颜色。
- `spawn_weight`：作为随机池候选时的权重。

刷怪器位置：

- 脚本：`scripts/combat/enemies/enemy_spawner.gd`
- 场景节点：`scenes/game_scene/levels/survival_arena.tscn` 的 `EnemySpawner`

当前场景覆盖：

- `spawn_margin = 80.0`
- `vertical_padding = 52.0`
- `enemy_parent_path = ../EnemyRoot`
- `player_path = ../Player`
- `drop_receiver_path = ../Player`
- `boss_spawn_anchor_path = ../BossSpawn`
- `boss_reset_anchor_path = ../BossSpawn`

## 升级选项和经验

升级池位置：`scenes/game_scene/levels/survival_arena.gd`

- `UPGRADE_POOL`：当前升级抽取池。
- `FALLBACK_DAMAGE_UP_5`：没有可选升级时的兜底升级。

升级资源目录：`resources/upgrades/`

字段定义：`scripts/progression/upgrade_option_config.gd`

- `id`、`display_name`、`description`、`icon`
- `rarity`、`weight`
- `category`
- `modifier_type`
- `target_key`
- `operation`
- `value`
- `max_pick_count`
- `exclusive_group`
- `required_tags`
- `blocked_tags`
- `granted_tags`

经验系统位置：`scripts/progression/experience_system.gd`

- `level_thresholds = [10, 18, 28, 40, 55, 72, 90, 110, 135]`

当前 `survival_arena.tscn` 没有覆盖 `ExperienceSystem.level_thresholds`，所以使用脚本默认值。

## 其他战斗系统配置

自动瞄准：

- 节点：`scenes/game_scene/levels/survival_arena.tscn` 的 `GameSettings`
- 脚本：`scripts/systems/game_settings.gd`
- 字段：`auto_aim_enabled`

投射物挂载：

- 节点：`ProjectileFactory`
- 字段：`projectile_parent_path = ../ProjectileRoot`

结果页和商店页：

- 商店按钮和商店层在 `survival_arena.tscn`。
- 商店页面场景：`scenes/shop/shop_page.tscn`
- 商店脚本：`scenes/shop/shop_page.gd`
- 商店打开时会全局暂停，`ShopLayer` 使用 `process_mode = 3` 保证暂停时仍可操作。

## 常见需求速查

修改初始金币：

- 当前源头是 `scripts/player/player.gd` 的 `Player.reset_player()` 中 `current_gold = 0`。
- 如果只想改 `survival_arena`，建议在 `survival_arena.gd` 的 `player.reset_player()` 后设置 `player.current_gold`，并同步商店状态。

修改法术槽数量：

- 战斗商店施法栏数量：`survival_arena.gd` 的 `_configure_shop_state()`，改 `shop_run_state.spell_slot_count`。
- 默认数据类兜底值：`scripts/runtime/run_state.gd` 的 `spell_slot_count`。

修改背包容量：

- 战斗商店背包容量：`survival_arena.gd` 的 `_configure_shop_state()`，改 `shop_run_state.inventory_capacity`。
- 默认数据类兜底值：`scripts/runtime/run_state.gd` 的 `inventory_capacity`。

修改每波敌人数：

- `survival_arena.gd` 的 `WAVE_DEFS[*].count`。

修改每波出怪速度：

- `survival_arena.gd` 的 `WAVE_DEFS[*].interval`。

修改敌人强度和掉落：

- 普通敌人：`resources/enemies/enemy_normal_signal.tres`
- Boss：`resources/enemies/enemy_boss_signal.tres`
- 字段包括 `max_hp`、`move_speed`、`guaranteed_xp_drop`、`gold_drop_chance`、`gold_drop_amount_min/max`。

修改商店商品数量或刷新费用：

- `scripts/shop/shop_service.gd`
- `SHOP_OFFER_COUNT`
- `SHOP_BASE_REFRESH_COST`

修改法术价格或商店出现概率：

- 对应 `resources/spells/cards/*.tres`
- `buy_cost`
- `shop_weight`
- `can_appear_in_shop`
- `max_owned_count`

修改初始法杖牌组：

- `resources/spells/wands/combat_default_wand.tres`
- 修改 `deck`。

新增升级：

- 新建或复制 `resources/upgrades/*.tres`。
- 确认字段来自 `UpgradeOptionConfig`。
- 加入 `survival_arena.gd` 的 `UPGRADE_POOL`，否则战斗不会抽到。

新增敌人：

- 新建或复制 `resources/enemies/*.tres`。
- 若要让当前 `survival_arena` 使用，需要在 `survival_arena.gd` preload，并接入刷怪流程。

新增法术：

- 新建或复制 `resources/spells/cards/*.tres`。
- 加入 `resources/spells/spell_card_database.tres` 的 `cards` 数组。
- 如果要作为初始法术，加入 `resources/spells/wands/combat_default_wand.tres` 的 `deck`。

## 后续整理建议

如果后续配置会继续增多，建议新增一个资源类，例如 `CombatRunConfig` 或 `SurvivalArenaConfig`，把以下内容从脚本常量迁移到 `.tres`：

- 初始金币。
- 背包容量。
- 施法栏数量。
- 默认法杖。
- 法术数据库。
- 波次配置。
- 普通敌人池、精英敌人池、Boss 配置。
- 升级池。

这样策划调整时主要改 `.tres`，不用改脚本。
