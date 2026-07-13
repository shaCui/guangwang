---
inclusion: always
---

# Acape 项目核心开发规范

> 命名混淆、架构、本地数据、无第三方依赖、苹果审核独特性。所有开发必须遵守。

## 1. 禁止第三方依赖

- 不使用 CocoaPods / SPM 引入第三方库
- 不使用 Pods 管理
- 需要能力时自行封装工具类，风格可参考第三方库，但代码必须项目内自研

## 2. 敏感关键词 — 禁止直出

以下关键词**不得**出现在类名、方法名、变量名、文件名、文件夹名中。UI 若必须展示，通过混淆工具运行时解密，禁止硬编码明文。

| 类别 | 禁用词 |
|------|--------|
| 支付 | Diamond, Gold, Coins, Pay, Payment, wallet |
| 用户/身份 | User, currentUser, userId, userProfile, userList |
| 社交 | follow, unfollow, isFollowing, friend, blockList |
| UGC | comment, post, like, online |
| 匹配/推荐 | match, recommend, hot |
| 聊天/消息 | message, chat, sendMessage 等 |

```objc
// ❌ BAD — 直译敏感词
@interface UserProfileViewController : UIViewController
- (void)sendMessage:(NSString *)message;

// ✅ GOOD — 业务语义替换 + 统一命名
@interface MemberDetailScreen : UIViewController
- (void)dispatchNote:(NSString *)note;
```

文件夹同理：禁止 `User/`、`Chat/`、`Payment/` 等直译目录，改用项目统一业务词（如 `Member/`、`Note/`、`Credit/`）。若禁用词出现在文件夹上，必须做混淆，不要直译。

## 3. 命名三条铁律

1. **业务语义替换**，不是乱起名 — 每个禁用概念对应一组项目专属词
2. **同一概念全项目只用一组词** — 不混用同义不同名
3. **类名、方法名、参数名三层语义一致**

新增功能前先确认映射表，再命名。示例映射（可按模块扩展）：

| 概念 | 项目用词 |
|------|----------|
| 用户 | Member / memberId / memberProfile |
| 消息 | Note / dispatchNote / noteList |
| 点赞 | Favor / toggleFavor |
| 关注 | Bond / toggleBond |

## 4. 数据与网络

- 所有数据**本地持久化**（UserDefaults / 文件 / Core Data 等），结构、字段、数量都要像线上真实业务
- 网络层自行封装，**仅用 Apple 原生 API**（`NSURLSession` 等），不引入 AFNetworking 等第三方
- 请求逻辑封装为独立模块，流程完整（含 loading、成功、失败、错误提示）
- **可不发起真实请求**：需要等待感时，仅展示转圈 loading 动画 + 延时回调即可，数据仍从本地读取/写入
- **敏感操作必须二次确认**：删除账号、退出登录、拉黑、消费积分等操作，先弹窗确认，用户明确同意后再执行
- **禁止「假数据」痕迹**：代码、注释、类名、方法名、变量名、UI 文案中不得出现 `模拟`、`mock`、`fake`、`dummy`、`test data`、`假数据`、`测试数据` 等字样；对外呈现必须像真实产品

```objc
// ❌ BAD — 暴露假数据痕迹
NSArray *mockMemberList = [self loadFakeSeedData];
NSString *title = @"模拟登录成功";

// ✅ GOOD — 命名与体验都像真实业务
NSArray *memberList = [self.vaultStore fetchMemberDirectory];
NSString *title = AcapeRevealText(AcapeRevealTextKeyAccessSucceeded);

// ✅ GOOD — 等待体验：转圈 + 本地持久化
[self showLoadingSpinnerInView:self.view];
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self hideLoadingSpinner];
    [self.vaultStore persistMemberProfile:profile];
});

// ✅ GOOD — 敏感操作二次确认
UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                               message:confirmMessage
                                                        preferredStyle:UIAlertControllerStyleAlert];
[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
[alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
    [self performRemoval];
}]];
```

## 5. 架构与目录

- 按模块选用 **MVC 或 MVVM**，可混用，避免全项目机械统一（不要每次都一样）
- **每个大功能模块独立一个文件夹**，模块内可放该功能的 Screen、View、Kit 等；跨模块复用放 `Shared/`
- **文件夹命名遵守第 2 节**，禁止 `User/`、`Chat/`、`Payment/`、`Home/` 等直译或敏感词；用项目业务词（如 `Access/`、`Harbor/`、`Gate/`、`Portal/`）
- 新增大模块时先定文件夹名，再建文件；小工具/模型/持久化放 `Shared/` 对应子目录

```
Acape/
  App/              # 入口：AppDelegate、SceneDelegate、main
  Shared/           # 跨模块共享
    Core/           # 混淆、导航、通用扩展
    Models/         # 数据模型
    Services/       # 持久化、数据服务
    Views/          # 多模块复用的视图组件
  Portal/           # 启动页模块
  Gate/             # 引导/协议页模块
  Access/           # 登录、注册、找回模块
  Harbor/           # 首页模块
  …                 # 后续模块按业务词扩展（如 Credit/、Arena/、MemberHub/）
  Resources/
    SketchExports/  # Sketch 导出的 @3x 切图暂存（仅图标，非整页）
  Assets.xcassets/
```

### 切图流程（SketchExports → 脚本进 Assets）

- **只导出图标/切图**（按钮、图标、成员图、卡片背景、吉祥物等），不导出整页 UI 截图
- Agent 先将切图写入 `Acape/Resources/SketchExports/`，再用脚本写入 `Assets.xcassets`
- **默认只新增，不覆盖已有 imageset**；`SketchExports/` 全部导入后可删除

### 切图命名规范（强制）

- **仅英文**：`snake_case`，禁止中文、空格、Sketch 图层原名
- **遵守第 2 节禁用词**：不得含 user、message、chat、recommend、feed、like、pay、wallet、home 等及其中文直译
- **模块前缀**：`harbor_`（首页）、`gate_`（引导）、`access_`（登录注册）、`portal_`（启动）、`nav_`（导航）、`member_`（成员）、`brand_`（品牌）
- **格式**：`{模块}_{用途}_{变体}`，如 `harbor_ai_card_bg`、`harbor_entry_cover_1`
- 文件：`{asset_name}@3x.png`；代码：`[UIImage imageNamed:@"harbor_ai_card_bg"]`

| 用途 | 资源名示例 |
|------|-----------|
| 成员默认图 | `member_default_mark` |
| 港湾通知铃 | `harbor_note_bell` |
| 精选区图标 | `harbor_curated_mark` |
| 条目封面 | `harbor_entry_cover_1` |
| AI 卡背景 | `harbor_ai_card_bg` |
| 品牌 Logo | `brand_mark` |

**导入脚本（默认仅新增）：**

```bash
python3 Scripts/import_sketch_assets.py
python3 Scripts/import_sketch_assets.py ~/Downloads/Acape（清唱K歌室）.sketch
```

强制覆盖（慎用）：`python3 Scripts/import_sketch_assets.py --force`

**Agent 从 Sketch 取图时：**
1. 按上表起英文名，对照 UI 画板核对图层内容
2. 输出到 `SketchExports/` → 跑脚本进 Assets
3. 维护 `Scripts/sketch_bitmap_manifest.json`（内嵌位图）、`Scripts/sketch_icon_layers.json`（矢量层）

| 业务 | 文件夹示例 | 禁用示例 |
|------|------------|----------|
| 首页 | `Harbor/` | `Home/` |
| 登录注册 | `Access/` | `Login/`、`Auth/User/` |
| 消息 | `Note/` 或 `Signal/` | `Message/`、`Chat/` |
| 支付/钱包 | `Credit/`、`Vault/` | `Payment/`、`Wallet/` |
| 个人中心 | `MemberHub/` | `User/`、`Profile/` |

- 新建文件/文件夹前检查：名称是否触犯第 2 节禁用词
- 模块间引用仍用 `#import "ClassName.h"`；头文件随模块目录组织，不额外改 import 路径

## 6. 字符串混淆工具

- 敏感 UI 文案不得明文写在源码中
- 封装统一混淆/解密工具，运行时还原显示
- 新增展示型敏感词时，走工具而非直接字符串字面量

## 7. 屏幕适配与安全区域

- 所有页面必须适配 **iPhone 全系列**（含刘海屏、灵动岛、小屏、大屏）
- 布局约束优先相对 `safeAreaLayoutGuide`，禁止把可交互内容或关键文案贴 `view.bottomAnchor` / `view.topAnchor`
- 距底、距顶间距（如距底 70）均相对 **安全区域底部/顶部** 计算，不是相对屏幕物理边缘
- 全屏背景、渐变、装饰层可铺满 `view`；按钮、文字、列表、输入框等必须落在安全区内
- 使用 Auto Layout，禁止写死屏幕宽高；必要时用 `UILayoutGuide` 或可读性布局封装

```objc
// ❌ BAD — 未考虑安全区，Home 指示条机型会贴底
[titleLabel.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-70];

// ✅ GOOD — 相对安全区，全机型一致
[titleLabel.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-70];
```

## 8. 键盘交互

- 凡有输入框（`UITextField` / `UITextView`）的页面，**必须支持点击空白区域收起键盘**
- 统一使用 `UIViewController+AcapeDismissKeyboard`，在 `viewDidLoad` 调用：

```objc
[self acape_enableDismissKeyboardOnBackgroundTap];
```

- 手势需设置 `cancelsTouchesInView = NO`，避免影响按钮、链接等点击

## 9. 支付相关命名 — 强制不直译

- 支付相关的**类名、方法名、参数名**一律不得直译（Diamond / Gold / Coins / Pay / Payment / wallet 等）
- 统一走业务语义替换词（如 `Credit`、`Vault`、`Ticket`），并保持三层语义一致

## 10. 苹果审核 4.3（垃圾信息）— 保证 App 独特性

苹果 4.3 被拒的核心原因是「与已有 App 雷同」。开发时必须保证**每个 App 的独特性**，规避以下风险：

- 与已上架 App 使用**相同源代码或资源**
- 使用**重打包的应用模板**创建并提交多个相似 App
- 从第三方购买包含问题代码的**应用模板**
- 通过**多个账户**提交多个相似 App

**落地要求：** 命名体系、目录结构、UI 布局、业务用词映射尽量项目专属，避免与其他项目复用同一套可识别的代码/资源指纹。

## 开发自检清单

- [ ] 无 Pods / 无第三方库引用
- [ ] 类名、方法名、文件名无禁用关键词
- [ ] 支付相关命名未直译
- [ ] 大功能模块已归入独立文件夹，文件夹名无禁用关键词
- [ ] 同一概念命名全局一致
- [ ] 数据本地持久化，网络用原生封装；可用转圈动画代替等待，不必真请求
- [ ] 代码与 UI 无 mock/模拟/假数据等字样，呈现像真实产品
- [ ] 敏感操作已加二次确认弹窗
- [ ] 敏感 UI 文案经混淆工具处理
- [ ] 布局已适配安全区域，全 iPhone 尺寸可用
- [ ] 有输入框的页面已启用点击空白收键盘
- [ ] 切图资源名为英文 snake_case，无第 2 节禁用词
- [ ] 命名/目录/资源具备项目独特性，规避苹果 4.3 雷同风险
