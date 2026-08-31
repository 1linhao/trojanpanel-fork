# Trojan Panel 可组合 UI 资源库重构方案

> 状态：保留的目标架构与历史迁移设计；继续开发先读 [当前状态](README.md)，不要重复执行已完成阶段<br>
> 编写日期：2026-08-27<br>
> 原始视觉金样（2026-08-27，不覆盖后续已确认的视觉调整）：`trojan-panel-ui` 的 `codex/frosted-glass-ui` 分支，提交 `4c61e6b3c98e3757bdbc979479bd79d43bc5ccca`<br>
> 根仓库基线：`0d2922f095a241792a3f8990763af1b4922a1c53`<br>
> 历史回退镜像记录（执行回退前重新确认可用性）：`trojan-panel-ui:frosted-glass-20260827T095456Z-4c61e6b`

## 1. 文档目的

本次重构要把当前 Web UI 拆成三类可独立替换、按统一契约组合的资源库：

1. **组件库**：负责控件语义、交互、可访问性和几何结构。
2. **材质库**：负责颜色、透明度、模糊、边框、阴影、状态色和动效质感。
3. **布局库**：负责应用壳层、导航、内容区、响应式断点和插槽位置。

业务应用只在一个 Composition Root（组合入口）选择并组装它们。更换材质不应修改组件或布局源码，更换布局不应改写组件，更换业务数据源也不应进入资源库内部。

这不是一次视觉改版。拆分期间必须以当前磨砂玻璃版本为视觉与行为金样，先做到等价抽取，再允许后续创建其他材质包。Liqui Design 可作为未来真正液态玻璃材质的视觉参考，但不属于本阶段交付。

## 2. 设计术语

- **Module（模块）**：具有稳定职责、独立入口和独立验证方式的资源包。
- **Interface（接口）**：调用方允许依赖的公开导出、CSS 变量、属性和事件。
- **Implementation（实现）**：模块内部 DOM、类名、算法和样式文件，不对外承诺稳定。
- **Seam（接缝）**：两个模块之间唯一允许发生依赖的位置，例如语义属性和 CSS Custom Properties。
- **Adapter（适配器）**：把 Vuex、Router、权限、API 等业务概念转换为资源库契约的应用内代码。
- **Locality（局部性）**：一次业务改动应尽量只触及业务层；一次材质改动只触及材质包。

判断拆分是否成功的核心问题是：删除某个模块后，它维护的约束会不会被复制到多个调用方。如果会，该模块有存在价值；如果只是转发参数，它只是薄包装，应合并或深化。

## 3. 原始问题与重构动机（2026-08-27 快照）

以下为重构起点的审计，不是当前代码缺陷清单；其中旧样式文件、结构组件和图标实现已部分移除。仍未迁移的边界见 [当前状态](README.md)。当时存在下列耦合：

- `prototype-runtime.scss`、`liquid-glass.scss` 等全局样式同时包含材质、组件结构和业务页面选择器。
- 样式中约有 200 处 `#app`、132 处 `!important`、256 个十六进制颜色和 117 处业务选择器，材质无法安全替换。
- `LiquidStructural` 将表格、表单、弹窗、卡片、描述列表、栅格、滚动条、Tooltip、Dropdown 等集中在一个大模块中，公共接口过宽。
- `src/layout/index.vue` 同时处理布局、路由、角色权限、Vuex、预览 Token、退出登录、品牌文案和响应式导航。
- 主题、反馈、Loading 分散在 `theme.js`、`liquid-feedback.js`、`liquid-loading.js`，覆盖层级和视觉协议没有单一所有者。
- 部分组件依赖全局注册，业务页面难以判断真实依赖，也不利于按需引入和逐步迁移。

历史上的共享包接入曾把尚未达到视觉等价的 `@liqui/liquid-ui` 与 `@liqui/liquid-app-shell` 批量接入业务，结果线上呈现成半成品液态玻璃。新方案必须将“构建资源包”和“迁移 Trojan Panel”分成两条有门禁的流水线。

## 4. `/home/lh/git/liqui` 的参考结论

参考文件：

- `/home/lh/git/liqui/liquid-ui/package.json`
- `/home/lh/git/liqui/liquid-ui/src/core.js`
- `/home/lh/git/liqui/liquid-ui/src/vue2.js`
- `/home/lh/git/liqui/liquid-ui/src/material/`
- `/home/lh/git/liqui/liquid-app-shell/src/contracts.js`
- `/home/lh/git/liqui/` 下的 integration lab 与 reference app

### 4.1 直接采用的模式

- 使用 `package.json#exports` 明确根入口和子路径入口，禁止调用方进入 `src/`。
- Framework-neutral Core 与 Vue 2 Adapter 分离。
- Shell 输入先经过纯函数标准化、唯一键校验和冻结，再交给视图渲染。
- 每个资源包可独立执行 `check`、`test`、`build` 和导出检查。
- 建立 Integration Lab 与第二消费者，证明包不是只对 Trojan Panel 特化。

### 4.2 必须调整的模式

| Liqui 现状 | 本方案调整 | 原因 |
| --- | --- | --- |
| Material 与组件同属 `liquid-ui` | 材质独立为平行包 | 才能真正任意搭配 |
| Shell 直接 peer-depend UI 包 | Shell 只依赖契约与 Vue | 防止布局绑定某套控件 |
| 插件默认全量全局注册 | 命名导出、按需注册优先 | 支持树摇与渐进迁移 |
| 液态玻璃效果作为默认实现 | 当前磨砂玻璃为生产金样 | 防止抽取变成视觉改版 |
| 使用仓库外 `file:../../liqui` 接入 | 包放入同一 monorepo/workspace | 保证干净克隆可复现 |

### 4.3 明确不采用

- 不复制尚未达到当前产品视觉质量的材质实现。
- 不以绝对路径、兄弟仓库相对路径或未固定 Git 地址作为生产依赖。
- 不先替换业务页面再补资源包能力。
- 不把所有组件塞进一个自动安装的全局插件。
- 不在一次提交中同时迁移 Shell、表格、表单、浮层和主题。

## 5. 目标模块与目录

建议先放入 `trojan-panel-ui` monorepo，成熟后再决定是否独立发布：

```text
trojan-panel-ui/
├── packages/
│   ├── ui-contracts/
│   ├── ui-components-vue2/
│   ├── ui-material-frosted/
│   ├── ui-layout-app-shell-vue2/
│   ├── ui-icons/
│   └── ui-material-flat-test/       # private，仅用于验证可替换性
├── examples/
│   ├── integration-lab/
│   └── minimal-lab/
└── src/
    ├── adapters/
    │   ├── trojan-panel-shell.js
    │   └── trojan-panel-ui-composition.js
    └── ...                           # 业务代码
```

### 5.1 `@tp-ui/contracts`

职责：定义所有包共同理解、但不包含视觉实现的最小语义契约。

公开内容：

- Surface、Tone、Size、Density、State 枚举及校验器。
- ThemeState、MaterialCapability、ShellModel 等数据模型。
- CSS Custom Property 名称清单与默认安全回退值。
- 稳定的 `data-ui-*` 语义属性规则。
- `createUiRuntime()`：只负责状态组合、能力查询和订阅，不操作业务 Router/Vuex。

禁止内容：Vue 组件、业务角色、路由路径、网络请求、具体颜色、具体模糊值。

### 5.2 `@tp-ui/components-vue2`

职责：提供控件的行为、DOM anatomy、键盘交互、焦点管理、可访问性和几何样式。

首批公开组件：Button、IconButton、Input、NumberInput、Select、DatePicker、Switch、SegmentedControl、Tag、Dialog、Dropdown、Tooltip、Loading、Table、Form primitives、Feedback。

约束：

- 只 peer-depend Vue 2，并依赖 `@tp-ui/contracts`。
- 组件颜色、背景、边框和阴影只能消费语义变量，不写材质值。
- 内部类名属于 Implementation；调用方只能使用 props、events、slots、parts、CSS vars 和 `data-ui-*`。
- 默认使用命名导出。允许 `createVue2Components({ include })` 生成选择性插件，但禁止默认安装全部组件。
- 表格横向滚动必须只有一个真实滚动容器，表头与内容共享坐标系。
- Dialog、Dropdown、DatePicker popup、Tooltip、Loading 必须共享 Overlay/Portal/Stack 接口。

### 5.3 `@tp-ui/material-frosted`

职责：完整复现当前磨砂玻璃版本的视觉语言。

包括：

- 日间/夜间模式及现有颜色主题。
- Canvas、Panel、Raised、Overlay、Control、Navigation 等 Surface 配方。
- 模糊、透明度、反色字体描边、边缘高光、阴影、状态色、交互态与 reduced-motion 策略。
- 浏览器 `theme-color`/`color-scheme` 计算策略。
- 能力检测和无 `backdrop-filter` 时的降级值。

禁止内容：组件 DOM 选择器、业务类名、`#app .account-list` 一类规则、路由、Vuex。

材质只允许通过下列接口影响界面：

1. 在根节点设置主题/调色板数据属性。
2. 为稳定的 `data-ui-surface`、`data-ui-tone` 等语义属性赋 CSS 变量。
3. 实现公开的 Material Controller 接口。

### 5.4 `@tp-ui/layout-app-shell-vue2`

职责：提供应用外壳的几何布局和响应式行为。

包括：Header、Desktop navigation、Mobile navigation、Content viewport、User actions、Brand、Route title、插槽区域和横向导航滚动。

约束：

- 只依赖 `@tp-ui/contracts`，peer-depend Vue 2。
- 不直接依赖组件包或材质包。
- 内部交互使用语义 HTML；图标、用户组件、附加动作通过 slots/renderer 传入。
- 接收归一化 ShellModel，向外只发 `navigate`、`logout`、`action` 等意图事件。
- 不读取 Vuex、Router、Token、角色或用户 API。

### 5.5 `@tp-ui/icons`

职责：统一图标轮廓、线宽、尺寸、光学对齐和语义名称。

图标不得硬编码与背景相同的颜色；默认继承 `currentColor`。Shell 与组件通过 icon registry 或 slot 使用它，不建立反向依赖。

### 5.6 应用内 Adapter

`src/adapters/trojan-panel-shell.js` 是业务与资源库之间的隔离层，负责：

- 从 Vuex/Router/Auth 读取当前用户、角色和路由。
- 生成规范化 ShellModel。
- 将 `navigate`、`logout` 意图映射回 Router/Store。
- 管理管理员/普通用户的入口差异。

`trojan-panel-ui-composition.js` 是唯一组合入口，负责选择材质、布局、组件清单与图标集。业务页面不得自行切换材质实现。

## 6. 依赖方向

```text
                         ┌────────────────────────────┐
                         │ Trojan Panel composition   │
                         │ root + business adapters   │
                         └───────┬───────┬───────┬────┘
                                 │       │       │
             ┌───────────────────┘       │       └──────────────────┐
             ▼                           ▼                          ▼
  components-vue2              layout-app-shell-vue2         material-frosted
             │                           │                          │
             └───────────────────┬───────┴──────────────────────────┘
                                 ▼
                            ui-contracts

  icons 由 composition root 注入组件或布局；不反向依赖任何上层包。
```

禁止循环依赖。材质、组件和布局彼此平行，不得互相 import 实现代码。

## 7. 统一引用契约

### 7.1 语义属性

稳定属性至少包括：

```html
<section
  data-ui-surface="panel"
  data-ui-tone="neutral"
  data-ui-density="comfortable"
  data-ui-state="idle"
></section>
```

允许值：

- `data-ui-surface`: `canvas | panel | raised | overlay | control | navigation`
- `data-ui-tone`: `neutral | accent | success | warning | danger | info`
- `data-ui-density`: `compact | comfortable | spacious`
- `data-ui-state`: `idle | hover | active | selected | disabled | loading | invalid`

业务含义如 `admin`、`server-online`、`traffic-reset` 不得进入通用语义契约；业务层应先映射成 tone/state。

### 7.2 CSS 变量

契约包维护变量清单，材质包赋值，组件和布局消费：

```css
--ui-canvas-bg
--ui-surface-bg
--ui-surface-border
--ui-surface-shadow
--ui-surface-backdrop
--ui-ink
--ui-ink-muted
--ui-accent
--ui-focus-ring
--ui-control-bg
--ui-control-border
--ui-control-height
--ui-radius-sm
--ui-radius-md
--ui-radius-lg
--ui-space-1 ... --ui-space-8
--ui-motion-fast
--ui-motion-normal
--ui-overlay-z
```

几何变量可由组件/布局提供默认值，材质只覆盖视觉语义变量。不得把 `.liquid-button__label` 等内部类作为跨包接缝。

### 7.3 JS Runtime 接口

示意接口：

```js
const runtime = createUiRuntime({
  material: createFrostedMaterial(),
  initialTheme: { mode: 'system', palette: 'blue' }
})

runtime.theme.getState()
runtime.theme.setMode('dark')
runtime.theme.setPalette('violet')
runtime.theme.subscribe(listener)
runtime.material.getCapabilities()
```

Runtime 不应成为全局服务定位器。组件只接收它真正需要的子接口，并在测试中可传入最小 fake。

### 7.4 组合入口示例

```js
import Vue from 'vue'
import { createUiRuntime } from '@tp-ui/contracts'
import { createFrostedMaterial } from '@tp-ui/material-frosted'
import { createVue2Components } from '@tp-ui/components-vue2'
import { createAppShell } from '@tp-ui/layout-app-shell-vue2'

import '@tp-ui/components-vue2/geometry.css'
import '@tp-ui/layout-app-shell-vue2/layout.css'
import '@tp-ui/material-frosted/material.css'

const runtime = createUiRuntime({ material: createFrostedMaterial() })

Vue.use(createVue2Components({
  runtime,
  include: ['UiButton', 'UiInput', 'UiSelect', 'UiDialog']
}))
Vue.use(createAppShell({ runtime }))
```

固定样式顺序：契约回退/基础层 → 组件几何 → 布局几何 → 选定材质。每层只能覆盖自己拥有的变量，禁止靠提高选择器权重争夺所有权。

## 8. 强制引用规则

1. 只允许从包公开 `exports` 导入，禁止 `/src/` 深层导入。
2. 业务 View 不得导入材质或布局内部文件。
3. 材质不得选择业务类名、组件内部类名或 `#app`。
4. 业务样式不得选择资源包内部类名；使用公开 variant、slot、part 或 CSS vars。
5. Workspace 内使用锁定的 workspace 依赖；禁止 `file:../../`、绝对路径和未固定 Git 依赖。
6. 所有包必须在干净克隆环境中安装、构建和测试成功。
7. ESLint `no-restricted-imports`、Stylelint 与 dependency-cruiser/Madge 在 CI 中阻止越层和循环依赖。
8. 硬编码色值只允许出现在材质包的 token 源文件；测试快照和 SVG 特殊资产须列白名单。
9. `!important` 默认禁止；确有平台覆盖需求时必须带原因注释并登记例外。
10. 全局注册仅存在于应用迁移 Adapter，不属于组件库默认接口，迁移完成后删除。

## 9. 资源包公开接口规范

每个包必须包含：

- `README.md`：职责、非职责、安装、组合示例、兼容矩阵。
- `package.json#exports`：根入口、必要子入口、样式入口和 `package.json`。
- `CHANGELOG.md` 和 SemVer 策略。
- `src/index.js`：唯一汇总公开面。
- `test/contract/`：接口契约测试。
- `scripts/check-exports.mjs`：检查声明与实际产物一致。
- `npm run check`：至少执行 lint、test、build、exports check、pack smoke test。

内部目录不得被文档示例或业务代码引用。公开接口变化须先更新契约测试和迁移说明。

## 10. 证明“可随意搭配”的最低组合矩阵

仅拆成多个目录不算解耦。必须运行以下组合：

| 示例 | 组件 | 布局 | 材质 | 目的 |
| --- | --- | --- | --- | --- |
| Integration Lab A | Vue2 components | AppShell | Frosted | 验证生产组合 |
| Integration Lab B | 同一组件 | 同一 AppShell | Flat Test | 证明材质可替换 |
| Minimal Lab | 同一组件 | Minimal host layout | Frosted | 证明布局可替换 |

`ui-material-flat-test` 只需高对比纯色，但必须实现完整材质契约。若更换它需要修改组件或 Shell，说明 Seam 设计失败。

## 11. 原始分阶段迁移计划

阶段顺序保留作架构参考；Phase 0/1 与按钮、面板、图标等部分生产迁移已实施。不能把下面的计划逐项当作当前未完成任务。

### Phase 0：冻结金样与行为基线

- 以 UI 提交 `4c61e6b` 建立桌面/手机、日间/夜间、现有色系的截图金样。
- 记录登录/注册、首页、账号、节点、服务器、个人资料和关键二级面板。
- 为日期切换、表格同步滚动、Overlay、主题持久化、移动导航建立行为测试。
- 禁止在本阶段改色、改圆角、改布局或引入 Liqui Design 折射。

门禁：任何人能从干净克隆复现基线，视觉快照和关键行为测试稳定。

### Phase 1：契约与实验室

- 建立 workspace、`ui-contracts`、包边界检查和 Integration Lab。
- 定义全部语义属性、变量、模型与验证器。
- 同时实现 Frosted 与 Flat Test 两个最小材质，先证明切换机制。
- 尚不接入 Trojan Panel 业务入口。

门禁：两个材质可在 Lab 中切换且无需修改组件/布局。

### Phase 2：抽取磨砂材质

- 从全局 SCSS 逐条把 token、surface、tone、theme、overlay 视觉值迁入 `material-frosted`。
- 业务选择器保留在应用侧，先映射语义属性，再删除旧规则。
- 每迁移一种 Surface，执行完整主题/色系截图对比。

门禁：视觉差异在批准阈值内；材质包中业务选择器、`#app`、组件内部类名均为 0。

### Phase 3：迁移基础组件

推荐顺序：Button/Icon → Input/NumberInput → Select/Segmented/Switch/Tag → Overlay/Feedback → DatePicker → Form/Table。

每个组件执行同一循环：

1. 写公开接口和行为测试。
2. 在 Integration Lab 实现并通过双材质。
3. 只迁移一个业务调用点。
4. 对比视觉、键盘、触摸和主题状态。
5. 扩大调用范围。
6. 删除旧实现和兼容 Adapter。

禁止一次删除上千行旧样式后再补齐效果。

### Phase 4：迁移 AppShell

- 先实现纯 ShellModel 与模型校验。
- 将当前 `layout/index.vue` 中 Vuex、Router、角色和 Logout 移到应用 Adapter。
- Shell 用 slot 接入图标、用户组件和动作。
- 桌面与手机导航使用同一模型；手机入口完整、横向滑动无可见滚动条。

门禁：AppShell package 不出现业务路径、角色判断、Vuex/Router import；Minimal Lab 可独立使用。

### Phase 5：清债与发布

- 删除旧全局注册、旧结构组件和已迁移的全局覆盖。
- 执行无 ElementUI、无越层导入、无重复实现检查。
- 检查按需引入、路由懒加载和包体积预算。
- 仅在用户明确要求时部署；部署前固定精确提交、构建产物和可回退镜像。

## 12. 关键组件验收要求

### 表格

- 表头与内容共享横向滚动坐标，不得用两个独立滚动容器模拟同步。
- 横纵滚动条使用同一全局几何和材质变量。
- 不需要滚动时轨道可隐藏，但若产品要求保留占位，必须由公开 prop 控制。
- 手机上列表不能继续纵向滚动时，手势自然交还页面。
- 滚动条角落不得出现不受主题控制的白色方块。

### Select、Dropdown 与 DatePicker

- 展开层统一使用 Overlay + `surface="overlay"`，位于正确顶层。
- Trigger 整框响应点击，有合理统一的最大宽度。
- 日期面板包含日期输入框与选择器；日/月/年显示格式统一。
- 月选择的年份、定位、手机尺寸和边界翻转均有测试。

### Dialog、Feedback 与 Loading

- 由单一 OverlayStack 管理 z-index、焦点、背景遮罩和滚动锁。
- 动画开始时材质已生效，不能在动画结束瞬间才加入模糊。
- 手机 Dialog 不得超出视口；导出等面板 y 轴位置合理。
- Loading 挂在页面顶层，圆形背景内严格居中，不被内容 overflow 裁剪。
- 触摸结束后不得残留 active/pressed 状态。

### 主题

- 首次载入可跟随浏览器主题；浏览器主题改变时，未手动锁定的页面实时响应。
- 用户手动设置按当前产品要求持久化到浏览器本地。
- `theme-color`、`color-scheme` 与页面当前模式同步；浏览器不支持时应无害降级。
- 所有状态色经 Tone token 映射，业务页面不得独立硬编码同义颜色。

## 13. 测试与质量门禁

### 自动测试

- Contracts：枚举、模型标准化、重复键、无效输入、冻结对象、变量完整性。
- Components：键盘、焦点、ARIA、v-model、disabled/loading/invalid、触摸状态。
- Material：所有必需 token、Surface、Tone、两种模式、现有调色板、能力降级。
- Shell：导航模型、受控 activeKey、意图事件、手机横向导航、插槽。
- Architecture：禁止跨层 import、循环依赖、深层 import、业务选择器进入包。
- Packaging：独立 build、exports、`npm pack` 后从临时消费者导入。

### 视觉回归矩阵

至少覆盖：

- 2 种模式：light / dark。
- 当前全部调色板。
- 3 类视口：桌面、窄桌面、手机。
- idle、hover、focus-visible、active、selected、disabled、loading、invalid。
- 页面：登录/注册、Dashboard、账号、节点、服务器、个人资料。
- 浮层：Select、DatePicker、Dropdown、Tooltip、Dialog、Confirm、Prompt、Loading。

金样来自当前磨砂玻璃提交，而不是 `/home/lh/git/liqui` 的视觉输出。

### 静态零容忍指标

资源包中必须达到：

- ElementUI 依赖和 `el-*` 组件：0。
- 业务类选择器：0。
- `#app`：0。
- 未登记的 `!important`：0。
- 材质包之外未批准的硬编码颜色：0。
- 循环依赖：0。
- 包外 `/src/` 深层导入：0。

## 14. 完成定义

只有同时满足以下条件，重构才算完成：

1. 三类资源库和契约包能独立检查、构建、打包和被临时项目导入。
2. 三种组合矩阵全部运行，不修改资源包内部实现即可换材质或换布局。
3. Trojan Panel 关键页面和流程与 `4c61e6b` 金样视觉、行为等价。
4. 应用业务代码只通过公开接口使用组件；材质与布局只在组合入口选择。
5. Shell 中不存在 Vuex、Router、Token、角色、API 和产品文案耦合。
6. 旧实现、迁移 Adapter 和双轨样式在对应迁移完成后被删除。
7. 无 ElementUI，静态零容忍指标全部通过。
8. 路由懒加载和按需组件引入生效，首屏及路由 chunk 不超过基线预算。
9. 干净克隆可复现，README、迁移指南、API 文档与变更日志齐全。

## 15. 非目标

- 不在本次抽取中重做成 Liqui Design 的正统液态玻璃。
- 不进行 Vue 3 迁移。
- 不修改后端接口、权限模型或业务流程。
- 不用资源库重构顺便处理无关业务 Bug。
- 不因“更现代”而改变当前磨砂玻璃金样；新视觉应作为后续独立材质包评审。

## 16. 风险与回退策略

| 风险 | 防护 |
| --- | --- |
| 抽取时发生视觉漂移 | 截图金样、逐组件迁移、双材质 Lab |
| 包拆多但仍隐式耦合 | 第二材质、第二布局、依赖规则和深层导入门禁 |
| Overlay 分散导致压暗/裁剪复发 | 单一 OverlayStack 和接口级测试 |
| 全局插件导致包体积回升 | 命名导出、选择性插件、chunk budget |
| 本机可用但 CI/他人不可复现 | workspace、lockfile、clean clone、pack smoke test |
| 一次性替换造成线上半成品 | 资源包门禁通过后才允许单调用点迁移 |

每个 Phase 都应保留可运行提交。禁止在没有精确镜像标签和健康检查时覆盖唯一回退容器。

## 17. 决策记录

- **ADR-001**：当前 `4c61e6b` 磨砂玻璃实现是本次视觉金样。
- **ADR-002**：语义属性 + CSS Custom Properties 是材质与组件/布局之间的主要 Seam。
- **ADR-003**：AppShell 不直接依赖组件包或材质包。
- **ADR-004**：组件默认命名导出和按需注册，不默认全量全局安装。
- **ADR-005**：资源包先在 monorepo 与 Lab 中独立成熟，再接入产品。
- **ADR-006**：必须存在 Flat Test 材质和 Minimal Layout，作为解耦的可执行证明。
- **ADR-007**：`/home/lh/git/liqui` 仅作拆分模式参考，不作为生产路径依赖或视觉金样。

## 18. 后续开发入口

先阅读 [当前状态](README.md)、[待办](TODO.md) 和相关包 README，再按源码确认未迁移范围。保留当前分支与工作树，不从历史金样重新建分支，不重建已有 workspace，不恢复已删除的 Liquid/Sprite 兼容实现。

## 19. 继续迁移的验证要求

每次只迁移明确范围，记录公开接口、依赖边界、测试结果、视觉对比和剩余风险。执行资源包检查、相关回归测试及生产构建；未获用户授权不部署。最新测试证据见 [验证记录](代码审查.md)，历史通过记录不代替当前复验。

## 20. 动画资源扩展（2026-08-27 补充）

后续动画引擎按第四类可替换资源接入，不归材质、组件或布局私有所有。Phase 1 先建立 `@tp-ui/motion-native` 与 Motion Controller 接缝；现有生产动画在对应组件迁移时再逐项抽取，避免在基线未冻结前批量改动。

公开契约至少包括：

- `MotionMode`: `system | full | reduced | none`。
- `runtime.motion.getState()`、`setMode()`、`subscribe()` 与 `getCapabilities()`。
- 稳定根属性 `data-ui-motion="full|reduced|none"`。
- `--ui-motion-fast/normal/slow`、标准/强调 easing、位移距离等语义变量。
- Motion Controller 只实现 `apply(state)` 与 `getCapabilities()`；未来 Web Animations、View Transitions 或第三方动画引擎可实现同一接口。

约束：

1. 组件和布局只能引用语义动画变量或控制器能力，不得 import 动画包实现。
2. 材质可提供视觉状态，但不拥有动画时间线；动画包不得写颜色、背景、边框或阴影。
3. `prefers-reduced-motion` 必须由环境适配器映射，`none` 模式应无害关闭动画与平滑滚动。
4. Integration Lab 必须验证默认动画与关闭动画可切换，且不修改组件、布局或材质源码。
5. 现有动画按 Button/Input → Overlay/Feedback → DatePicker → Shell/Page transition 顺序迁移，并保留视觉与行为回归。

- **ADR-008**：动画是可选的平行资源；Composition Root 通过 Motion Controller 注入，资源包只依赖契约。

## 21. 统一按钮交互（2026-08-28 补充）

Phase 2/3 将导航栏的精细指针悬浮反馈提升为所有按钮共享的交互契约。不同按钮保留各自的 Vue 结构、语义、尺寸、颜色和业务行为，只统一可替换的动画层：

- 稳定 Interface：`data-ui-interaction="nav-lift"`。
- 默认 CSS Adapter：桌面精细指针悬浮上移 `3px`，复用导航栏阴影与高光；按下缩放；disabled/`aria-disabled` 不触发。Controller 记录按钮静止命中矩形，通过 `data-ui-hovered` 保持上移后空隙内的稳定悬浮，越过静止边界后才退出。
- 发现范围：原生 `button` 和语义 `[role="button"]`，包含懒加载组件与动态 Overlay 内容。
- Motion 集成：`system/full/reduced/none` 继续由 `@tp-ui/motion-native` 控制；reduced 模式取消位移和缩放。
- 扩展 Seam：动画 Adapter 只实现 `connect(element)`、`disconnect(element)`、`destroy()`，未来接入 WAAPI 或第三方引擎时只修改生产 Composition Adapter。

专用控件（日期格、Switch、分页、Segmented 等）不得为了统一动画而强制套用通用按钮 DOM；它们通过相同 Interface 共享交互，实现仍归各自 Module 所有。

- **ADR-009**：按钮统一的是交互 Interface，而非单一 DOM 外壳；生产 Composition Adapter 负责发现和连接，业务 View 不依赖动画实现。
