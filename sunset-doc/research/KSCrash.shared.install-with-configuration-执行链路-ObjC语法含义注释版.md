# KSCrash.shared.install(with: configuration) 执行链路（Obj-C 语法含义注释版）

## 0. 你现在最需要先掌握的 10 个 Obj-C 语法点

1. `+` 方法：类方法（相当于 Swift 的 `static/class func`）。
2. `-` 方法：实例方法（相当于 Swift 的实例 `func`）。
3. `@property(...)`：声明属性，括号里是内存语义和线程语义。
4. `NS_SWIFT_NAME(...)`：告诉 Swift 导入时要改成什么名字。
5. `NSError **error`：Obj-C 传统错误输出参数，Swift 会桥成 `throws`。
6. `dispatch_once`：只执行一次，常用于单例。
7. `typedef struct { ... }`：C 结构体，跨 Obj-C/C 传配置时常用。
8. `static` 全局变量：进程级单例状态（例如是否已安装）。
9. `BOOL`：Obj-C 布尔（`YES/NO`），Swift 里会桥成 `Bool`。
10. `block` 与 C 函数指针：Obj-C 闭包和 C callback 互转要特别小心。

---

## 1. `KSCrash.shared` 是怎么来的

源码：`Sources/KSCrashRecording/include/KSCrash.h`

```objc
@property(class, atomic, readonly) KSCrash *sharedInstance NS_SWIFT_NAME(shared);
```

语法拆解：

1. `property(class, ...)`：这是类属性，不是实例属性。
2. `atomic`：默认线程安全语义（但不代表业务逻辑完全线程安全）。
3. `readonly`：外部只读。
4. `NS_SWIFT_NAME(shared)`：Swift 里名字变成 `shared`。

所以 Swift 里你写的是：

```swift
KSCrash.shared
```

而不是 `sharedInstance`。

---

## 2. `install(with:)` 为什么是 `throws`

Obj-C 原型：

```objc
- (BOOL)installWithConfiguration:(KSCrashConfiguration *)configuration error:(NSError **)error;
```

语法拆解：

1. `-`：实例方法。
2. 返回 `BOOL`：成功/失败。
3. `error:(NSError **)error`：二级指针，让方法内部把错误对象“回填”给调用方。

Swift 导入后，通常变成：

```swift
try KSCrash.shared.install(with: configuration)
```

即：

1. `BOOL + NSError**` 桥接为 `throws`。
2. 失败时用 `throw` 代替 Obj-C 里返回 `NO` + 填 `error`。

---

## 3. 单例是如何构建的（`dispatch_once`）

源码：`Sources/KSCrashRecording/KSCrash.m`

```objc
+ (instancetype)sharedInstance
{
    static KSCrash *sharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedInstance = [[KSCrash alloc] init];
        gIsSharedInstanceCreated = YES;
    });
    return sharedInstance;
}
```

语法拆解：

1. `+ (instancetype)`：类方法，返回“当前类实例类型”。
2. `static` 局部静态变量：函数多次调用也只初始化一次。
3. `dispatch_once`：线程安全的一次性初始化。
4. `[[KSCrash alloc] init]`：Obj-C 对象创建标准写法。

对应 Swift 心智模型：

- 类似 `static let shared = KSCrash()` 的懒加载单例。

---

## 4. `installWithConfiguration:error:` 主体里的 Obj-C 关键语法

源码关键段：`KSCrash.m:302+`

```objc
self.configuration = [configuration copy] ?: [KSCrashConfiguration new];
self.configuration.installPath = configuration.installPath ?: kscrash_getDefaultInstallPath();
```

语法拆解：

1. `[obj method]`：Obj-C 消息发送语法。
2. `[configuration copy]`：调用 `NSCopying`，避免外部后续修改影响内部。
3. `?:`：空值兜底（如果左边是 `nil`，用右边）。

```objc
KSCrashReportStore *reportStore =
    [KSCrashReportStore storeWithConfiguration:self.configuration.reportStoreConfiguration error:error];
```

语法拆解：

1. `Type *name`：对象指针声明。
2. `storeWithConfiguration:error:`：类方法，命名风格体现第一个参数语义。
3. Obj-C 多参数方法名是“分段式”的，不是一个整体函数名。

```objc
KSCrashCConfiguration config = [self.configuration toCConfiguration];
KSCrashInstallErrorCode result =
    kscrash_install(self.bundleName.UTF8String, self.configuration.installPath.UTF8String, &config);
KSCrashCConfiguration_Release(&config);
```

语法拆解：

1. `KSCrashCConfiguration`：C 结构体，不是 Obj-C 对象。
2. `.UTF8String`：把 `NSString *` 转成 `const char *` 给 C 层。
3. `&config`：取地址，传指针给 C 函数。
4. `Release(&config)`：手动释放 C 层内存（不是 ARC 管理）。

---

## 5. `if (error != NULL) { *error = ... }` 怎么理解

源码：`KSCrash.m:324-327`

```objc
if (error != NULL) {
    *error = [KSCrash errorForInstallErrorCode:result];
}
```

语法拆解：

1. `error` 是 `NSError **`（指向指针）。
2. `*error` 才是“调用方持有的 NSError* 变量”。
3. 赋值给 `*error` 才能把错误传出函数。

对应 Swift：

- 这段会被桥成 `throw`，你通常看不到 `NSError **` 细节。

---

## 6. `@property` 常见修饰符在这条链路里的真实含义

例子：

```objc
@property(nonatomic, strong) KSCrashConfiguration *configuration;
@property(class, atomic, readonly) KSCrash *sharedInstance;
```

要点：

1. `strong`：ARC 强引用，持有对象生命周期。
2. `copy`：常用于 `NSString/NSArray/NSDictionary`，防止可变对象被外部改动。
3. `nonatomic`：不加锁，性能更好；`atomic`：setter/getter 原子化。
4. `class`：类属性。
5. `readonly`：只读属性。

---

## 7. C 层 `kscrash_install` 里的语法你需要会读哪些

### 7.1 全局安装状态

```c
static volatile bool g_installed = 0;
```

含义：

1. `static`：文件内可见。
2. `volatile`：提示编译器不要过度优化该变量读写。
3. `bool`：C 布尔类型。

### 7.2 结构体配置

```c
typedef struct {
    KSCrashReportStoreCConfiguration reportStoreConfiguration;
    KSCrashMonitorType monitors;
    ...
} KSCrashCConfiguration;
```

含义：

1. 这是 C ABI 友好的配置包。
2. Obj-C 层先把对象配置 flatten 成 C struct 再传入。

### 7.3 函数指针回调

```c
static void onExceptionEvent(struct KSCrash_MonitorContext *monitorContext, KSCrash_ReportResult *result)
```

配合：

```c
kscm_setEventCallbackWithResult(onExceptionEvent);
```

含义：

1. 把函数地址注册给 monitor 框架。
2. 后续 crash 发生时由 monitor 反调这个函数。

---

## 8. block 和 C callback 的桥接（高风险语法点）

源码：`KSCrashConfiguration.m:111-124`

KSCrash 里有兼容老 API 的写法，把 Obj-C block 转 C 函数指针（`imp_implementationWithBlock`）。

你现在只要记住：

1. 这种桥接存在签名匹配风险。
2. 在 crash-time 场景尤其要关注 async-safety。
3. 新 API 已经引导你用带 plan 的 callback，少碰旧 callback。

---

## 9. 从 Swift 视角反推 Obj-C/C（你在调试时可直接套用）

当你看到：

```swift
do {
  try KSCrash.shared.install(with: config)
} catch {
  ...
}
```

你要立刻想到 Obj-C/C 在做：

1. Obj-C `installWithConfiguration:error:` 是否返回 `NO`。
2. `NSError` 是否来自 `errorForInstallErrorCode` 的映射。
3. C `kscrash_install` 失败点是路径、monitor 激活、还是参数。
4. debugger 是否导致 monitor 被屏蔽。

---

## 10. 给你的一条实战建议

以后你看到 Obj-C 签名里有 `NSError **`、`const char *`、`struct`、`callback`，就直接判定这段代码是“桥接层”或“底层边界层”，优先检查：

1. 生命周期（`copy/strong`）
2. 指针与内存释放（`&`、`Release`）
3. 线程/上下文约束（debugger、安全回调、async-safe）

这三个维度比背语法更值钱。
