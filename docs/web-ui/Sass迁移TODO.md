# Sass `@import` 迁移记录（已完成）

当前 UI 使用 Dart Sass `1.103.1`。`trojan-panel-ui/src/styles/index.scss` 共有 10 条 `@import`，当前构建警告由其中 5 个本地 SCSS 入口触发；其余 Sass 文件没有跨文件变量、mixin 或函数依赖。迁移目标是消除警告，同时保持现有样式加载顺序、资源包边界和视觉结果不变。

## 待办

- [x] 记录迁移前基线：运行 `npm run lint`、`npm run test:ui-cleanup`、`npm run test:ui-libraries`、`npm run build`，保存构建警告与关键页面截图。
- [x] 将 `src/styles/index.scss` 的本地 SCSS 入口按原顺序改为 `@use`；未使用 `--silence-deprecation=import`。
- [x] 资源包 CSS 改由 `src/main.js` 按 contracts → motion → component geometry → layout → interactions → production material → overlay 顺序显式导入；本地结构与运行时样式随后由 `index.scss` 加载。
- [x] 未顺带改写业务样式结构或扩大视觉范围。
- [x] 增加静态门禁，禁止业务 Sass 新增 `@import`，但允许普通 CSS `@import url(...)`。
- [x] 完整自动验证通过，生产构建不再出现 Sass `@import` 弃用警告。
- [x] 本地业务 E2E 复核登录、Dashboard、系统设置、三类模板、移动导航、38 个交互按钮和浏览器控制台；历史四断点/四色实屏基线继续保留在全页面检查记录中。

## 完成标准

- `src/styles/index.scss` 不再使用 Sass `@import`，构建无对应弃用警告。
- 自动门禁全部通过，产物中资源包样式仅加载一次。
- 关键页面与迁移前基线无非预期视觉差异；若必须改变层叠顺序，需在交接记录中说明原因和受影响选择器。

完成日期：2026-09-02 CST。迁移采用“资源包 CSS 由 JS 显式加载、本地 SCSS 使用 `@use`”方案；构建由 249 个模块变为 256 个模块是 7 个公开 CSS 入口被 Vite 分别解析的预期结果，最终产物样式体积保持一致。
