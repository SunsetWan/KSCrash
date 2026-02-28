# KSCrash 实战学习计划（DemoProj）

## 结论
你这个学习方法非常好：在 Demo 项目里手动制造 crash，再回看 KSCrash 源码调用链，是最高效的学习路径之一。

## 为什么这个方法有效
1. 你在做“可控输入 -> 可观测输出 -> 反查源码”，比纯读源码更快形成系统认知。
2. KSCrash 是事件驱动链路，手动触发更容易看清 monitor 到 report 的真实路径。

## 推荐实验顺序（由浅到深）
1. `Signal/Mach` 崩溃（例如非法内存访问）。
2. `NSException`（例如数组越界）。
3. `UserReported`（业务主动上报）。
4. `Watchdog/Hang`（主线程卡死，需要启用对应 monitor）。
5. `OOM breadcrumb`（最后做，链路更长）。

## 重点补充：为什么“调试器下很多 monitor 会被屏蔽”

这句话的意思是：

1. 当 App 被 Xcode 调试器附加时，KSCrash 会检测“当前正在被调试”。
2. 对于会和调试器冲突的 monitor（典型是 Mach Exception），KSCrash 会自动禁用，避免和调试器抢异常处理权。
3. 结果就是：你在 Xcode 里看到崩溃了，但 KSCrash 不一定按你预期写出完整报告，容易误以为“链路没走到”。

简化理解：
- **附加调试器时**：为了安全，KSCrash 会“收敛能力”。  
- **不附加调试器时**：才更接近真实线上行为。

## 如何做一轮“非 debugger 附加”验证
你至少做一轮下面任意一种：

1. Xcode `Edit Scheme` -> `Run` -> 关闭 `Debug executable`，再运行触发 crash。  
2. 先用 Xcode 安装 App 到模拟器/真机，然后从桌面图标直接启动 App（不从 Xcode 点 Run）。  
3. 触发 crash 后重启 App，检查 KSCrash 的 report 文件和字段是否完整。

### 操作方法（推荐顺序）

#### 方案 A：用 Scheme 关闭调试器附加（最直接）
1. Xcode 顶部选择当前 Scheme，点 `Edit Scheme...`。  
2. 选择左侧 `Run`。  
3. 在 `Info` 页签里，取消勾选 `Debug executable`。  
4. 重新 `Run` App。此时 App 会启动，但不会被 LLDB 调试器附加。  
5. 在 App 内点击你准备好的“触发 crash”按钮。  
6. App 崩溃后，再次启动 App，读取 KSCrash 报告并核对字段。

#### 方案 B：安装后从桌面图标启动（最接近线上）
1. 先在 Xcode 里正常运行一次，把 App 安装到模拟器或真机。  
2. 停止 Xcode 运行（`Stop`）。  
3. 不通过 Xcode，直接在模拟器/真机桌面点击 App 图标启动。  
4. 在 App 内触发 crash。  
5. 再次从桌面图标启动 App，读取并检查 KSCrash 报告。

### 验证成功的检查点（你可以逐条打勾）
1. 崩溃类型对应的 `monitorId` 符合预期（如 `MachException`/`Signal`/`NSException`）。  
2. `error.type` 与触发方式一致。  
3. 报告里有 `run_id`、线程信息（如 `threads`）等关键字段。  
4. 对比“附加调试器”和“非附加调试器”两次结果，能看到 monitor 或字段完整度差异。

### 常见误区
1. 只在 Xcode 附加调试器场景下验证，然后误以为 KSCrash 没工作。  
2. 触发 crash 后没有“重启 App 再读报告”，导致看不到落盘结果。  
3. 在同一轮实验中混用了多种触发方式，最后无法对应 `monitorId`。

## 学习执行建议
每次实验都按同一模板记录：
1. 触发方式（哪类 crash）。
2. 预期 monitor（例如 `Signal` / `NSException` / `Watchdog`）。
3. 实际 report 关键字段（`monitorId`、`error.type`、`threads`、`run_id`）。
4. 反查源码入口函数（monitor -> `notify` -> `handle` -> `writeStandardReport`）。
