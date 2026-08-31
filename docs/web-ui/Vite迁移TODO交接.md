## 2026-08-30 00:32

# Trojan Panel UI 迁移 Vite：TODO 交接

## 目标

- [x] 将 `trojan-panel-ui` 从 Vue CLI 4 / Webpack 4 迁移到 Vite。
- [x] 解决现代 Node.js/OpenSSL 3 下 Webpack 4 的 MD4 兼容错误。
- [x] 迁移后不再依赖 `NODE_OPTIONS=--openssl-legacy-provider`。
- [x] 保持现有 Vue 2 业务功能、UI、API、路由和 `dist/` 输出目录不变。

## 初始交接快照（2026-08-30 00:32，执行前重新核对）

- 根仓库：`/home/lh/git/trojanpanel-fork`
- UI 子模块：`/home/lh/git/trojanpanel-fork/trojan-panel-ui`
- 当前分支：`codex/composable-ui-library-refactor`
- 根仓库基准提交：`5ea06e3`
- UI 子模块基准提交：`ba21b57`
- 当前主要版本：Vue `2.6.14`、Vue CLI `4.5.17`、Webpack `4.46.0`
- 当前 Node.js：`v22.23.2`，OpenSSL：`3.6.4`

后续 UI 清理已改变工作树及图标实现。上述提交与版本仅为初始记录，不能据此回退代码；先阅读 [当前 UI 状态](README.md)，保留现有未提交修改。

## 研究与实施 TODO

- [x] 研究适合 Vue 2 的 Vite 版本和插件组合；优先评估 Vue 2.7 + 官方 `@vitejs/plugin-vue2`。
- [x] 评估 Vue 2.6 → 2.7 对现有组件、`vue-template-compiler` 和工作区包的影响。
- [x] 新建 Vite 配置，迁移路径别名、开发端口、`/api` 代理、输出目录和分包策略。
- [x] 把 `public/index.html` 改成 Vite HTML 入口。
- [x] 将 `VUE_APP_*`、`process.env` 改为 Vite 环境变量和 `import.meta.env`。
- [x] 将 `src/settings.js` 从 CommonJS 改为 ESM。
- [x] 保留 `AppIcon` / `@tp-ui/icons` 内联 SVG 方案及源码别名；`src/icons/index.js` 和 Sprite 消费组件已删除，不再恢复 `#icon-[name]` 契约。核实无引用后清理剩余 Sprite loader 配置、依赖和历史静态资源。
- [x] 移除 SCSS 包导入中的 Webpack `~` 前缀。
- [x] 清理无效的 `webpackChunkName` 注释，重新确认懒加载和分包结果。
- [x] 将 `serve`、`build`、`lint` 脚本从 `vue-cli-service` 迁出。
- [x] 研究生产代码混淆是否需要保留；如保留，改成 Vite/Rollup 兼容方案。
- [x] 更新 README 和安装脚本，删除 `--openssl-legacy-provider`。
- [x] 不更新系统软件；只允许修改项目依赖。

## 不在本次范围

- [ ] 不迁移 Vue 3。
- [ ] 不重构业务 UI、主题、动画、路由权限或 API。
- [ ] 不替换 Vue Router、Vuex、Vue I18n、Axios。
- [ ] 不改变后端接口、认证 token 和 hash 路由行为。
- [ ] 不删除 `packages/*` 下的可组合 UI 工作区包及其测试。

## 重点风险

- Vue 2 官方 Vite 插件要求 Vue 2.7，需要先确认升级影响。
- 图标已使用内联 SVG，但旧 Sprite loader 配置和依赖仍有残留；不要为适配构建而重新引入旧图标组件。
- 核对 `src/settings.js`、其余 `require.context`（若有）及 `process.env.VUE_APP_BASE_API` 的迁移。
- 现有 `webpack-obfuscator` 不能直接迁移到 Vite。
- 工作区源码别名可能造成重复 Vue 实例，需要检查 `resolve.dedupe`。
- 安装脚本依赖 `dist/`，迁移后必须保持目录兼容。

## 最低验收

- [x] 以下命令不带 OpenSSL legacy 参数并通过：

  ```bash
  npm run lint -- --no-fix
  npm run test:ui-libraries
  npm run test:ui-cleanup
  npm run build:ui-labs
  npm run build
  npm run test:live-stack:e2e
  ```

- [x] 模拟后端 `18081` 与前端 `18888` 可正常启动。
- [x] 登录、导航、系统配置、三种订阅模板编辑器和移动端导航可正常使用。
- [x] 浏览器控制台无模块加载、SVG、动态 chunk 和重复 Vue 错误。
- [x] `/api/*` 代理行为与迁移前一致。
- [x] UI 子模块提交后，在父仓库提交新的子模块指针。

## 给执行会话的提示词

```text
请在 /home/lh/git/trojanpanel-fork 当前分支上研究并执行 Vite 迁移，
以 /home/lh/git/trojanpanel-fork/docs/web-ui/Vite迁移TODO交接.md 为范围和验收依据。
先完成技术研究再实施；不要更新系统软件、迁移 Vue 3 或顺带重构业务 UI。
完成后运行现有 UI 库测试、生产构建和本地全栈 E2E，并提交 UI 子模块及父仓库指针。
```

---

## 2026-08-31 完成记录

- 用户要求关闭旧迁移分支后，已从重构分支最新父提交 `da6feee` / UI 提交 `4bea1d6` 重建 `codex/vite-migration`。UI 和安装脚本 stash 均恢复核对后删除；未覆盖重构分支的新 UI。
- 完成 Vue `2.7.16` + Vite `7.3.6` + 官方 Vue 2 插件 `2.3.4` 迁移，保留内联 SVG、工作区源码别名、hash 路由、`/api` 代理、生产混淆和 `dist/static` 输出。移除 Vue CLI/Webpack、Sprite loader/旧资源、legacy 参数及旧 Babel 配置。
- 最低验收六条命令全部通过，Node `22.23.2` / OpenSSL `3.6.4`，`NODE_OPTIONS` 为空。另通过 frozen-lockfile 安装、`test:vite-proxy`、`test:ui-labs:e2e` 和安装脚本 `bash -n`。
- 开发 `18888` 与生产预览 `18889` 连接模拟后端 `18081` 的 E2E 均通过，覆盖登录、系统配置、三种模板编辑/格式化、切换状态保留、移动导航及浏览器错误。未执行真实数据库/节点验证、远程 CI 或生产部署。
- 验收发现原有表格接收 `null` 的首帧报错；通过最小空值判断修复，并新增真实 Vue 渲染回归测试（修复前失败，修复后通过），没有改动业务界面。
- 保留限制：Vue 2 EOL；Sass `@import` 弃用提示；已有路由名 `index` 重复 warning（按范围不修改路由）。无模块加载、SVG、动态 chunk 或重复 Vue 实例错误。
- 提交：UI `48a3465`，安装脚本 `39ba03a`；父仓库同步这两个子模块指针。
- 详细研究与验收见 [Vite迁移研究与实施](Vite迁移研究与实施.md)。历史执行提示词仅用于背景，迁移已完成，不需要重做。

---
