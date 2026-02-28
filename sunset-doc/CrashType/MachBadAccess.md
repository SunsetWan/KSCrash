# MachBadAccess

## 问题一：如何分析 `Thread 1: EXC_BAD_ACCESS (code=1, address=0x1)`

## 0. 直接读这条报错（速判）

`Thread 1: EXC_BAD_ACCESS (code=1, address=0x1)` 可拆成三层：

1. `EXC_BAD_ACCESS`：发生了非法内存访问。
2. `code=1`：通常对应 `KERN_INVALID_ADDRESS`，表示地址本身无效（未映射）。
3. `address=0x1`：极低地址，常见于接近空指针的访问（如 `NULL/nil + 偏移`）。

实战结论：先按“无效地址访问”路径排查，而不是按业务异常排查。

补充对照（便于记忆）：

1. `code=1`：`KERN_INVALID_ADDRESS`（地址无效）。
2. `code=2`：`KERN_PROTECTION_FAILURE`（地址可能有效，但访问权限不允许）。

---

## 1. 先定性

这条错误可以先这样读：

1. `EXC_BAD_ACCESS`：内存访问异常（访问了不该访问的地址）。
2. `code=1`：通常对应 `KERN_INVALID_ADDRESS`（地址无效，不在可访问映射中）。
3. `address=0x1`：极低地址，通常是“接近空指针”的访问（例如 `NULL + 偏移`、悬垂指针被破坏成低值）。

结论：这是“非法内存读写”优先，不是业务逻辑异常。

---

## 2. 你在 Xcode 里应立即做的 6 步

1. 看崩溃线程（`Thread 1`）的调用栈，先定位你代码里的第一帧。
2. 打开寄存器视图，重点看触发访问时参与寻址的寄存器（`x0/x1/...`）。
3. 比较 `pc` 和异常地址：
   - 一般 `pc != 0x1` 时，多为“坏指针数据访问”。
   - `pc == 异常地址` 时，才偏向“坏函数指针跳转”。
4. 回看该帧的对象来源：是否可能已释放、越界、或跨线程并发读写。
5. 若涉及 Obj-C/CF 对象生命周期，开启 Zombies 再跑一轮。
6. 若涉及 C/UnsafePointer，开启 Address Sanitizer 再跑一轮。

---

## 3. 在 Swift 项目中最常见的触发来源

1. `UnsafePointer/UnsafeMutablePointer` 使用错误。
2. `unowned` 引用在对象释放后被访问。
3. Swift 与 C/Obj-C/CF 桥接时生命周期管理不当。
4. 数组或缓冲区越界（尤其是手动内存操作）。
5. 多线程竞争导致对象或内存状态被提前破坏。

---

## 4. 与 KSCrash 报告对齐时看什么

1. `error.type` 是否为 `mach`/`signal`。
2. `mach.exception`、`mach.code`（或对应 signal 字段）是否指向 bad access。
3. `faultAddress` 是否接近 `0x0/0x1`。
4. `crashed thread` 的 frame 0/1/2 是否能映射到你的实验代码。
5. `threads` 中是否有并发线索（可疑后台线程、锁竞争路径）。

---

## 5. 一个实战判断模板（可复用）

1. 这是 `KERN_INVALID_ADDRESS` 还是 `KERN_PROTECTION_FAILURE`？
2. 异常地址是低地址（`0x0/0x1/0x10`）还是高地址（野指针/内存破坏）？
3. `pc` 与异常地址是否一致？
4. 崩溃点访问的对象是谁创建、谁持有、谁释放？
5. 加上 ASan/Zombies 后是否更早、更明确地报出根因？

---

## 6. 对你这个报错的首轮结论

`Thread 1: EXC_BAD_ACCESS (code=1, address=0x1)` 在首轮通常按“无效地址访问（接近空指针）”处理。  
第一优先级是定位该线程栈顶帧里的对象来源与生命周期，再用 ASan/Zombies 缩小到具体代码行。
