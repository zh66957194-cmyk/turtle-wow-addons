# ToTPlus 插件说明

显示「目标的目标」和「目标的目标的目标」的**名字**，并支持点击选中。

## 为什么单独做一个插件

之前把这段功能加进 UnitEnhance 时，因为语法错误导致整个 UnitEnhance 加载失败（头像数值面板一起消失）。
所以拆成独立插件：即使 ToTPlus 出错，也不会影响头像增强。

## 实测发现

本客户端**支持三级目标链**，实测输出：

```
tt=Admins   ttt=癞皮狼
```

所以 `targettargettarget` 是可用的，之前判断「1.12 只到 targettarget」是错的
（当时目标是没有目标的友方 NPC，导致误判）。

## 显示

目标框下方两行，可点击：

```
┌──────────────┐
│ Admins       │  ← 目标的目标（浅黄），点击选中
│ 癞皮狼       │  ← 目标的目标的目标（浅蓝），点击选中
└──────────────┘
```

- 没有 ToT 时整块隐藏
- 有 ToT 无 ToToT 时只显示一行
- 点击行 = `TargetUnit("targettarget")` / `TargetUnit("targettargettarget")`

## 命令

```
/tot    在聊天栏打印当前目标链
```

## 验证

需要「目标本身有目标」才会显示，例如拉一只怪让它打你。

## 还原

复制回 `client\twmoa_1171_cn\Interface\AddOns\ToTPlus\`，然后完整重启客户端。