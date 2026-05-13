# Yiji Focus Float

`Yiji Focus Float` 会把一姬变成一只常驻桌面的本地任务小宠物。

它的使用逻辑很轻：

1. 双击一姬
2. 选一个任务类别
3. 让计时静静跑着
4. 再双击一姬结束这一段
5. 看 `Done Today` 和 `Done This Week` 把今天的努力长成可见的时间表

## 现在已经实现的内容

- 原生 `macOS` 桌面浮窗宠物
- 一姬可拖动摆放
- 开始任务时弹任务选项
- 任务类别目前包括：
  `开组会`、`seminar`、`读文献`、`洗数据`、`做模型`、`写论文`、`娱乐`、`饭饭`、`运动`、`家庭生活`
- 双击开始，双击结束
- 单击查看 `Done Today` 和 `Done This Week`
- 右键 `Quit`
- 每段任务自动记录开始和结束时间
- 收尾时可填写“这一段做成了什么”和“感觉如何”
- `Done Today` / `Done This Week` 以彩色时间块复盘
- 只有在没有活动任务、且明显久未动键鼠时才提醒
- 如果 `娱乐` 超过一小时，会额外提醒
- 数据只存在本机

## 权限说明

这只一姬在不给额外权限的情况下也能正常用：

- 双击开始 / 双击结束
- 单击看 `Done Today` 和 `Done This Week`
- `娱乐 1 小时` 提醒

如果想启用 `20 分钟没动键鼠` 的提醒，需要到：

`系统设置 -> 隐私与安全性 -> Input Monitoring`

把 `Yiji Focus Float.app` 加进去并打开。

如果不想给这个权限，也完全没关系，其他功能都可以照常使用，只是没有那条 `喵，人在干什么？` 的久未活动提醒。

## 现在的一姬文案

- 开始标题：`喵，离accept更近一步`
- 开始后提示：`喵，努力给咪挣罐罐鸭！`
- 结束按钮：`喵，人好棒！`
- 退出提示：`喵，退下吧人。`
- 久未活动提醒：`喵，人在干什么？`
- 娱乐过久提醒：`喵，不是说好要带咪发AER的吗？`

## 如何构建 app

在仓库根目录运行：

```bash
./plugins/yiji-focus-float/scripts/build-app.sh
```

会生成：

```text
plugins/yiji-focus-float/dist/Yiji Focus Float.app
```

## 如何快速测试

在仓库根目录运行：

```bash
./plugins/yiji-focus-float/scripts/run-desktop.sh
```


## 目录结构

- `desktop/`：原生 macOS app 代码
- `prototype/`：更早的原型和资源
- `prototype/assets/`：一姬静态图
- `prototype/motions/`：动作帧
- `scripts/build-app.sh`：构建 `.app`
- `scripts/run-desktop.sh`：构建并直接启动
- `scripts/make_share_kit.py`：生成四张说明图和长图

## 怎么自定义

### 改任务清单

编辑：

- `plugins/yiji-focus-float/desktop/YijiDesktopFloat.m`

搜索：

- `self.categories = @[`

如果也想让旧网页原型同步变化，再改：

- `plugins/yiji-focus-float/prototype/app.js`

### 改一姬的话

编辑：

- `plugins/yiji-focus-float/desktop/YijiDesktopFloat.m`

可以直接搜这些句子：

- `喵，离accept更近一步`
- `喵，努力给咪挣罐罐鸭！`
- `喵，人好棒！`
- `喵，退下吧人。`
- `喵，人在干什么？`
- `喵，不是说好要带咪发AER的吗？`

### 改图片和动作

现在桌面版主要用这些资源：

- `plugins/yiji-focus-float/prototype/assets/yiji-static-final.png`
- `plugins/yiji-focus-float/prototype/motions/idle/`
- `plugins/yiji-focus-float/prototype/motions/running/`
- `plugins/yiji-focus-float/prototype/motions/jumping/`
- `plugins/yiji-focus-float/prototype/motions/waving/`

动作逻辑目前是：

- `idle`：待机静止
- `running`：开始任务时短暂精神一下
- `jumping`：结束任务时开心一下
- `waving`：退出前挥爪说明天见

## 平台说明

现在这版只支持 `macOS`。

## License

MIT
