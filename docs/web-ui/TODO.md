# Web UI 待办

早期五类规范化问题已完成代码修复；继续复查发现的遗漏与验收边界登记在下方。可组合资源的后续迁移边界见 [当前状态](README.md)，不要将本列表理解为全部重构阶段均已完成。已完成的构建工具迁移不在本任务待办范围。

2026-09-01 worker 复审后的未通过源码项已完成针对性修复并通过自动门禁；这不等于全部实屏、真实提交或真实后端验收完成。以下受本轮禁止提交约束、mock 数据能力或实屏矩阵限制的事项继续保持开放。

## 待验收

以下事项源码层面已完成，但按验收口径需要实屏复核或真实后端确认后才能关闭：

- [ ] WEB-010：390×844 账号编辑 Dialog 的正向 Tab 焦点环已改为显式逐项循环并补真实 DOM 模型回归；仍需在手机实屏重走 12 个控件、二层日期弹窗、Escape 与焦点返回的完整流程。
- [ ] WEB-014（收尾）：实屏复现“第一新密码框已填写仍校验第二框并报空值”的原始反馈场景，确认修复生效（注册页、个人资料修改密码两处）。
- [ ] WEB-016（收尾）：前三处 LiquidTabs 与主题 radiogroup 已实屏通过；导出 mock 只有一个客户端，仍需至少两个真实客户端验证跨 tab 移动、模板/二维码重置和 tab↔tabpanel 关联。
- [x] WEB-021（收尾）：两个入口的 618×918 实屏均为 560×332 且安全区居中，已通过。
- [ ] WEB-023（收尾）：页码和每页条数收敛实屏已通过；mock 始终返回全部 36 行，仍需真实后端确认查询参数实际生效。
- [ ] WEB-028（收尾）：实屏覆盖 sm/md/lg、手机/平板/桌面、有无清空及长文本下 Select/DatePicker 尾部图标间距与文字显示空间（重点：内核版本通道 117px 控件“正式版”）。
- [ ] WEB-032（收尾）：实屏验证 Clash.Meta YAML 模板格式化按钮、错误提示不覆盖原文、注释与缩进保留情况；JSON 无回退。
- [x] WEB-033（收尾）：390/618/768/1280 四断点两行对齐已实屏通过；实现已收敛到结构样式单一所有者，不再依赖新增全局 `!important` 覆盖。

仍需真实提交/真实数据确认：WEB-014，以及 WEB-017/022/025/026/029/030 中受本轮禁止写入或 mock 缺字段影响的分支；自动测试不能替代这些验收。

2026-09-01全路由首轮审查已覆盖14个页面路由及重定向，含43个views文件的页面/子面板清点；其中12个路由补充本轮实屏，404及旧服务器详情为源码检查。详见[全页面规范化检查](全页面规范化检查.md)。这不是全断点、所有数据状态或真实后端验收通过。

## 已完成归档

- WEB-001：修复登录页注册入口点击无响应，并完成桌面与移动端回归。
- WEB-002：业务弹窗统一迁移到 `UiDialog` / `.tp-ui-dialog*`，移除 `LiquidDialog` Adapter 与旧兼容类；保留磨砂玻璃材质。
- WEB-003：移动端弹窗提升到导航栏之上，接入动态视口和底部安全区，内容区独立滚动。
- WEB-004：Select、Dropdown 与原型下拉项统一使用 Motion Token，并为 reduced-motion 提供降级。
- WEB-005：完成全局复查的六类残留清理：辅助文字与认证标签、404 共用面板、共享品牌名称/Logo、旧导航树及配套状态、失效控件样式。保留 AppMain 所需的 tagsView 缓存状态；删除无引用的 404 图片和旧导航专用依赖。
- WEB-006：手机二级弹窗改为安全区内垂直居中；一级面板与状态栏保持同一玻璃通透度，移除空闲态的 View Transition 背景采样隔离，动画接口改为按需启用。
- WEB-007：手机和平板（≤1060px）全局背景中央增加主题色光斑；沿用主题 Token 和背景动画，桌面不增加。
- WEB-008：导航栏、按钮及输入控件统一使用 `@tp-ui/icons` 的内联 SVG 描边；移除遮罩/Sprite 组件调用、按钮图标矩形底色、内阴影及额外留白。弹窗图标由组合层注入，保留加载旋转和下拉箭头动画。

- WEB-009：完成统一 OverlayStack、有效尺寸参数、图标/清空键盘语义、Motion 时序收敛、材质/几何单一所有者；复查修复 Portal 销毁残留、子浮层 Escape 拦截、分页滚动降级、材质串扰及可点击标签。生产调色板 164 项原 Token 值保持一致。
- WEB-011：移除按钮皮肤对共享过渡的覆盖，普通按钮和导航统一消费 300ms Motion Token；输入、数字、下拉、日期和开关控件自动关联表单项标签与错误提示。
- WEB-012：顶部账号头像和账号名组合为“我的”页入口，使用原生按钮并复用导航悬浮交互；退出按钮保持独立。
- WEB-013：清除输入、数字、下拉、日期组件在手机断点取消最大宽度的旧规则；搜索框消费同一420px上限并允许内部输入收缩。618px窗口实测节点搜索框从558px恢复到420px，个人页三个输入框均为420px，无页面横向溢出；补充样式回归测试。更窄手机尺寸仍需另行实屏覆盖。

- WEB-022：共享 `LiquidFormItem.validate` 按 `type: 'number'` 与数值型值比较范围，不再一律比较 `String(value).length`；字符串按字符数、数组按元素数校验，`type: 'number'` 下无法解析为有限数字的值判为错误。批量账号数量 5/6/500 及配额 -1/1024000 边界可通过。同步将四语言 `createBatchNumRange` 提示从 5–200 修正为后端 `CreateAccountBatchDto` 实际的 5–500；新增数值/字符串/数组边界回归测试（ui-cleanup.test.js）。
- WEB-023：Pagination 恢复受控契约：`handleCurrentChange`/`handleSizeChange` 先发 `update:page`/`update:limit` 供 `.sync` 更新父级状态，再发 `pagination` 通知查询；改变每页条数时按新容量收敛页码。新增事件顺序与页码收敛回归测试。

- WEB-015：服务器列表配额条移除固定45%演示值，新增 `trafficPercent`：combined 模式按 `totalUsed/totalLimit`，separate 模式先分别计算上传和下载的 `used/limit` 再取较大比例，限额为0（未上报/不限额）时进度条为空。mock 服务器补充与后端 `ServerTrafficStatusVo` 一致的 `trafficStatus` 数据（含上下行/总量、reached）。
- WEB-016：四处页签统一迁移到共享 `LiquidTabs` 组件（role=tab + aria-selected + roving tabindex，tab/tabpanel 的 id 与双向 ARIA 关联，ArrowLeft/Right/Home/End 焦点与激活联动）；首页流量周期组、排行周期组、服务器限额模式组补 `aria-pressed` 与 `aria-label`；主题 `LiquidPalettePicker` radiogroup 补方向键/Home/End 焦点管理与选中联动。桌面/移动导航沿用现有 `aria-current` 契约未改动。
- WEB-017：任务、账号、服务器、邮件、黑名单、节点六处原生列表统一空状态：请求失败显示“请求失败，请重试”，无数据显示“暂无数据”，样式对齐共享表格（`.tbl-empty`，节点栅格用 `.node-grid__empty`）。加载中仍由 `v-liquid-loading` 覆盖。
- WEB-018：LiquidInput 清空按钮在 `disabled`/`readonly` 下不再渲染，`clear()` 方法侧同步防护并对齐 Select/DatePicker 行为；新增 `readonly` prop 并透传原生字段，清空后焦点回到输入框。
- WEB-019：`LiquidDatePicker` 统一手输框与时间控件草稿状态：新增 `resolveDraftSelection`，手输文本自带时间时以手输为准，否则应用时间控件草稿；Enter 应用与点击确定走同一路径，不再被旧 `timeText` 覆盖。
- WEB-020：`LiquidCodeEditor` 接入 `liquid-form-control`/`liquid-control-emitter` 共享协议：textarea 注册到最近 FormItem，标签经 `aria-labelledby` 关联、控件错误与 FormItem 错误经 `aria-describedby`/`aria-invalid` 关联；显式可访问名称优先，组件内格式错误仍保留独立 alert。模板内容标签（`contentLabel`）可定位输入区。
- WEB-021：删除订阅导出弹窗在≤640px下的独立顶部对齐/高度覆盖（`align-self: flex-start`、`margin-top`、body `max-height` 覆盖已移除），节点页与普通用户首页两个入口共用同一组件，回归共享 Dialog 安全区居中规则。
- WEB-024：账号、节点、服务器、邮件、文件任务、黑名单六处列表由共享请求版本拥有 loading；旧响应、旧失败和卸载后的迟到结果均不再写回。内核页 `inventoryUnavailable` 时显示“内核清单不可用”替代描述表；轮询 `loadTasks` 在再次排程前检查组件销毁状态，迟到响应不再创建新 timer。
- WEB-025：删除无应用引用的 `NodeDetail.vue`/`NodeQrcode.vue` 组件；移除 `server-detail` 路由（依赖已无写入方的 nodeServerId Cookie，详情由服务器列表内嵌面板承载）、四语言 `serverDetail` 词条及面包屑登记。路由删除为源码级检查，未发现可达入口。
- WEB-026：普通用户首页“每月1日流量自动重置”改为消费真实策略：后端 `PanelGroupVo` 新增 `resetDownloadAndUploadMonth`（`service.PanelGroup` 读取系统设置），开启时显示原文案，关闭显示“不自动重置”，接口未返回策略时整块省略；mock 数据同步补充该字段。
- WEB-027：Web 文件上传统一待提交/上传中/失败/成功状态：失败不再清空草稿可直接重试，成功后清空 `fileList` 与原生 input；提交按钮 busy 防重入并显示“上传中…”。`ImportTip` 真正等待调用方验证/导入 Promise，失败后才释放 busy 并允许重试。
- WEB-028：全局 Select/DatePicker 分离 `--ui-control-size-padding-x/y` 标量 Token，不再对双值 shorthand 做 `calc` 算术；箭头/清空按钮消费明确的水平 padding、tail width/gap，sm/md/lg 与 clearable 共用同一几何规则，无页面级补丁。
- WEB-029：`timeStampToDate` 统一无效值占位：`undefined/null/''/0` 及无法解析的值返回“—”，不再输出 NaN 日期；内核任务历史 `createdAt` 通过 `formatTaskTime` 格式化，不再输出原始值。
- WEB-030：普通用户首页辅助小字接入 `--supporting-text-ink`：`hero-meta` 到期时间/可用节点、已用比例 `usage-label` 不再使用 ink-3/faint 40% 透明度。
- WEB-031：登录/注册原生输入改由其直接父级 `LiquidFormItem` 接管标签、change/blur 校验和实时错误 ARIA；不再把无法向后代 inject 的 mixin 挂在页面祖先。显隐按钮保留独立 `aria-label`/`aria-pressed`。
- WEB-032：YAML 与 JSON 成为共享编辑器平级语言能力：各自解析和格式化；YAML 格式化在校验成功后仅做表示安全的空白规范化，保留注释、锚点/别名、标量风格与语义，非法原文不覆盖。编辑器本地错误拥有 id/`aria-describedby` 并消费四语言错误前缀；系统设置保存先调用活动编辑器 `validate()`，无效内容不会进入 API。JSON 行为无回退。
- WEB-033：两行表单布局收敛到 `liquid-structural.scss` 单一结构规则，标签独占第一行、控件位于第二行；移除 `uniform-dialog-form` 的新增 `!important` 双轨覆盖，全部断点共用控件宽度上限。长标签换行不挤压框体。

最近登记：2026-09-01 CST。验证与边界见《代码审查》最新记录。
