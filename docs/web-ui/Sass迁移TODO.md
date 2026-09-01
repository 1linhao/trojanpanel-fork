# Sass `@import` 迁移交接 TODO

当前 UI 使用 Dart Sass `1.103.1`。`trojan-panel-ui/src/styles/index.scss` 共有 10 条 `@import`，当前构建警告由其中 5 个本地 SCSS 入口触发；其余 Sass 文件没有跨文件变量、mixin 或函数依赖。迁移目标是消除警告，同时保持现有样式加载顺序、资源包边界和视觉结果不变。

## 待办

- [ ] 记录迁移前基线：运行 `npm run lint`、`npm run test:ui-cleanup`、`npm run test:ui-libraries`、`npm run build`，保存构建警告与关键页面截图。
- [ ] 将 `src/styles/index.scss` 的本地 SCSS 入口按原顺序改为 `@use`；不要用 `--silence-deprecation=import` 作为最终方案。
- [ ] 处理 5 个资源包 CSS 入口：优先验证 Sass/Vite 别名下的 `@use '<path>.css'`；若解析或输出顺序不稳定，则由 `src/main.js` 显式导入，并保持 production → 本地结构/运行时 → motion/geometry/overlay/interactions 的现有层叠顺序。
- [ ] 不在本次迁移中顺带重构 `prototype-runtime.scss` 的本地 `@extend`，避免扩大视觉回归范围；后续如拆模块，再单独评估占位选择器或 mixin。
- [ ] 增加静态门禁，禁止业务 Sass 新增 `@import`，但不要误报普通 CSS 的 `@import url(...)`（若未来确有此用法）。
- [ ] 运行完整自动验证并确认构建日志不再出现 Sass `@import` 弃用警告。
- [ ] 实屏复核登录/注册、首页、系统设置、列表与二级弹窗，至少覆盖 390、618、768、1280 四个宽度及四个颜色主题，重点检查层叠顺序、玻璃材质、按钮动画、Overlay 和响应式布局。

## 完成标准

- `src/styles/index.scss` 不再使用 Sass `@import`，构建无对应弃用警告。
- 自动门禁全部通过，产物中资源包样式仅加载一次。
- 关键页面与迁移前基线无非预期视觉差异；若必须改变层叠顺序，需在交接记录中说明原因和受影响选择器。
