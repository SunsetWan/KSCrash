# sosumi.ai 使用指南：辅助阅读 Xcode 内存访问崩溃文档

## 0. 结论先行

可以。对你这类“要快速吃透 Apple 官方文档并映射到实战（KSCrash + Demo 验证）”的目标，`sosumi.ai` 明显更高效：

1. 它把 `developer.apple.com` 的 JS 渲染页面转成可直接读取的 Markdown。
2. 便于你在终端做检索、摘录、比对（`rg`/`sed`/笔记沉淀）。
3. 对 LLM/Agent 也更友好，减少“抓不到正文”的情况。

适用范围：快速读懂结构、提炼排查路径、生成学习笔记。  
不替代项：最终结论仍要回到 Xcode + 真机/模拟器复现验证。

---

## 1. 你这个场景的最小工作流（推荐）

目标文档：
- 原文：`https://developer.apple.com/documentation/xcode/investigating-memory-access-crashes`
- 可读版：`https://sosumi.ai/documentation/xcode/investigating-memory-access-crashes`

操作步骤：

1. 把域名从 `developer.apple.com` 替换为 `sosumi.ai`。
2. 先通读一次，拿到章节骨架（Exception Type/Subtype、VM Region、Backtrace、PC/LR 判定）。
3. 第二遍做“可执行摘录”：每一节转成你在 Demo 里能验证的检查动作。
4. 回到 `LearnKSCrash` 做 crash 复现，把现象和文档字段逐项对齐。

---

## 2. 命令行实操（可直接复制）

### 2.1 拉取文档为本地 Markdown

```bash
curl -sSL 'https://sosumi.ai/documentation/xcode/investigating-memory-access-crashes' \
  -o /tmp/investigating-memory-access-crashes.md
```

### 2.2 快速扫目录与关键字段

```bash
rg -n "Exception Type|Exception Subtype|VM Region Info|backtrace|program counter|link register|KERN_" \
  /tmp/investigating-memory-access-crashes.md
```

### 2.3 抽取你最关心的段落（示例）

```bash
sed -n '1,220p' /tmp/investigating-memory-access-crashes.md
```

---

## 3. 面向你当前学习目标的阅读框架

你现在在做 KSCrash 崩溃链路深挖，建议把这篇文档拆成 4 个“验证卡点”：

1. 崩溃类型识别卡点：
   - 先看 `EXC_BAD_ACCESS (SIGSEGV/SIGBUS)`。
   - 再看 `KERN_INVALID_ADDRESS` vs `KERN_PROTECTION_FAILURE`。
2. 地址空间定位卡点：
   - 用 `VM Region Info` 判断地址落在未映射区、受保护区、栈保护页等。
3. 栈与寄存器卡点：
   - 对比 `pc`（或 `rip`）和异常地址，区分“非法内存读写”还是“非法指令跳转”。
   - ARM64 下结合 `lr` 追溯错误跳转来源。
4. 工具联动卡点：
   - 按文档建议串 Address Sanitizer / UBSan / TSan / Guard Malloc 做二次定位。

这 4 点刚好可映射到你在 Demo 里的人工造 crash 与 KSCrash 日志比对。

---

## 4. 与 DemoProj 联动的建议（你的下一步）

1. 在 `LearnKSCrash` 先做 1 个稳定可复现的 `EXC_BAD_ACCESS`（如野指针或越界访问）。
2. 每次崩溃后收集三份材料：
   - Xcode 控制台/调试器信息
   - KSCrash 生成的 report
   - 这篇文档对应章节的“判定规则”
3. 用同一模板复盘：
   - `Exception Type/Subtype` 是什么
   - 异常地址在哪里（`VM Region Info`）
   - `pc` 与异常地址是否一致
   - 是否需要 `atos`/符号化继续追踪

---

## 5. 限制与注意事项

1. `sosumi.ai` 是非官方转换层，内容归 Apple 所有；关键结论建议回看官方原文核对。
2. 文档可读性提升不等于定位一定正确，内存破坏类问题仍要靠运行时工具和复现策略。
3. 某些跨链接内容（跳转到其他文档）需要继续替换域名或额外抓取。

---

## 6. 进阶用法（可选）

`sosumi.ai` 还提供 MCP 接入（`https://sosumi.ai/mcp`），适合让 Agent 直接检索 Apple 文档并返回 Markdown。  
如果你后面要批量研究（例如一组 Xcode crash 排查文档），MCP 方式会比手动开网页更快。

---

## 7. 一句话判断

对“阅读效率”这件事，`sosumi.ai` 值得用；对“问题定性与修复”，仍以 Xcode 复现链路和符号化证据为准。
