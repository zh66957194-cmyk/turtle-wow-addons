# CDTimers —— 射程着色

动作条上超出射程的技能图标会变红。

## 功能

- 轮询 `IsActionInRange(slot)`，超距时把图标 `SetVertexColor(1, 0.35, 0.35)`
- 每 12 帧刷新一次（约 0.2 秒），对性能影响可忽略
- 冷却数字由另一个插件 `ActionCooldownCount` 负责，本插件只管颜色

## 命令

```
/rc on      开启
/rc off     关闭
/rc         查看帮助
```

## 注意

- 无目标时，攻击类技能会判定为「超距」而变红，这是 `IsActionInRange` 的原生行为
- 1.12 的 Lua 5.0 没有 `#`，本插件全部用 `table.getn`

## 已知限制

- 只处理 `ActionButton1~120` 与姿态条，不含宠物动作条、载具条
- 如果某个按钮没变色，多半是它不挂在 `ActionButton` 命名空间下