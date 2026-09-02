# Web UI 当前状态

核对日期：2026-09-02；本轮发布前的生产基线为 UI 提交 `6986193`，规范化修复发布候选为 `01e8cab`。以下能力仍有真实后端验收边界，不能将自动门禁结果理解为所有业务数据分支均已覆盖。

## 已实现

- 保持磨砂玻璃视觉，不执行旧 LiquidUI 交接中的液态玻璃改版。
- [UI 工作区](../../trojan-panel-ui/packages/)已有 7 个资源包：contracts、components-vue2、layout-app-shell-vue2、material-frosted、material-flat-test、icons、motion-native；Integration / Minimal Lab 用于验证独立组合。
- 生产通过唯一 Composition Root 组合 Runtime、Frosted Material、选择性 Vue 2 组件和业务 Shell Adapter；`UiPanel`、`UiSheet`、`UiDialog` 均从包公开 exports 消费。
- `serve` / `build` 在入口执行前生成 7 个资源包的本地 `dist`，干净克隆不依赖预存包产物；Lab E2E 同样自行生成资源包与 Lab。
- 按钮共用 `nav-lift` 交互。控制器保留静止/当前视觉命中矩形，避免上移后底边反复进出 hover；专用控件保留自己的 DOM。
- 导航、按钮和输入控件共用内联 SVG 图标。旧遮罩图标、Sprite 注册入口及图标独立矩形底色已移除。
- 手机/平板背景中央新增主题色光斑；一级内容面板与状态栏共用玻璃通透度。
- 已清理旧导航树、失效结构组件、样式和文案；品牌 Logo/系统名、认证页与 404 使用共享实现。
- Confirm/Prompt 与普通 Dialog 共用覆盖层栈；统一焦点、Escape、滚动锁、卸载清理和移动安全区。Button/Select 使用有效的 sm/md/lg 尺寸，图标与清空操作补齐键盘语义。
- 生产颜色、阴影色、模糊与 Overlay 配方由 `material-frosted/production.css` 所有；跨包 `--ui-*` 变量在 contracts 登记并由架构门禁完整性校验。
- AppShell 保留 1060px 平板/移动导航断点、当前项自动显露及原生产几何；应用内旧布局规则和全部 Sass `@extend` 兼容别名已删除。

## 扩展边界与未迁移范围

- 组件、布局、材质、图标、动画由应用组合层连接。公开接口以各包 README 与契约测试为准。
- 按钮动画适配器暴露 `connect/disconnect/destroy`；组件保留 `motion-role`、`motion-key`、`data-ui-part`。
- View Transition 捕获仅在祖先显式设置 `data-ui-view-transitions="active"` 时启用，结束及失败时必须清除；空闲时不设置实际 `view-transition-name`，避免隔离玻璃背景采样。
- UI 规范化不等于所有业务控件已迁入资源包：完整表单/表格/选择器仍由应用 Composition Adapter 显式登记。生产 `src/layout/index.vue` 已消费通用 `UiAppShell`，角色、路由、品牌、个人资料、退出及本地角色预览由应用 Adapter/slot 保留。
- 模板增删接口与后续页面/面板变形动画属于预留能力，不在本次文档清理中自动实施。

## 后续入口

- [UI 待办与完成记录](TODO.md)
- [全页面规范化检查](全页面规范化检查.md)：14个页面路由的源码及实屏覆盖矩阵、遗漏与验收边界。
- [目标架构方案](可组合UI资源库重构方案.md)：基线审计与阶段计划是历史设计，不应从旧提交重新创建资源包。
- [API 接口映射](API接口映射.md)：UI数据接入参考，具体字段和限制以当前源码为准。
- [Sass `@import` 迁移记录](Sass迁移TODO.md)：已完成的 `@use`/显式 CSS 入口方案、验证步骤与完成标准。
- [验证历史](代码审查.md)：历史运行地址、截图及测试成功记录不等于本次重新执行。

本目录只维护UI重构与规范化相关文档。已完成的独立Vite迁移资料移至`docs/vite-migration/`，由[文档总导航](../README.md)索引；磨砂玻璃原型保留作UI设计参考，不作为当前实现或验收依据。

在 `trojan-panel-ui` 中验证：

```bash
npm run test:ui-cleanup
npm run test:ui-libraries
npx eslint --ext .js,.vue src tests/ui-cleanup.test.js
npm run build
```

Vite 无需 legacy 参数。当前 UI `127.0.0.1:18888` → mock API `127.0.0.1:18081`；全路由审查轮的 Lint、清理测试、资源包检查与构建通过。14 个页面路由均已源码检查，其中 12 个补充 618×918 实屏；复审指出的源码缺口已修复并由自动门禁覆盖。规范化修复已提交为 `01e8cab`，生产发布结果以对应发布操作和健康检查为准；真实数据库验收仍按 TODO 单独推进。基础启动说明见 [UI README](../../trojan-panel-ui/README.md)。
