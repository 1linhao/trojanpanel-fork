## 2026-08-30 00:32

# Trojan Panel UI 迁移 Vite：TODO 交接

## 目标

- [ ] 将 `trojan-panel-ui` 从 Vue CLI 4 / Webpack 4 迁移到 Vite。
- [ ] 解决现代 Node.js/OpenSSL 3 下 Webpack 4 的 MD4 兼容错误。
- [ ] 迁移后不再依赖 `NODE_OPTIONS=--openssl-legacy-provider`。
- [ ] 保持现有 Vue 2 业务功能、UI、API、路由和 `dist/` 输出目录不变。

## 当前状态

- 根仓库：`/home/lh/git/trojanpanel-fork`
- UI 子模块：`/home/lh/git/trojanpanel-fork/trojan-panel-ui`
- 当前分支：`codex/composable-ui-library-refactor`
- 根仓库基准提交：`5ea06e3`
- UI 子模块基准提交：`ba21b57`
- 当前主要版本：Vue `2.6.14`、Vue CLI `4.5.17`、Webpack `4.46.0`
- 当前 Node.js：`v22.23.2`，OpenSSL：`3.6.4`

## 研究与实施 TODO

- [ ] 研究适合 Vue 2 的 Vite 版本和插件组合；优先评估 Vue 2.7 + 官方 `@vitejs/plugin-vue2`。
- [ ] 评估 Vue 2.6 → 2.7 对现有组件、`vue-template-compiler` 和工作区包的影响。
- [ ] 新建 Vite 配置，迁移路径别名、开发端口、`/api` 代理、输出目录和分包策略。
- [ ] 把 `public/index.html` 改成 Vite HTML 入口。
- [ ] 将 `VUE_APP_*`、`process.env` 改为 Vite 环境变量和 `import.meta.env`。
- [ ] 将 `src/settings.js` 从 CommonJS 改为 ESM。
- [ ] 替换 `src/icons/index.js` 的 `require.context` 与 `svg-sprite-loader`，保持 `#icon-[name]` 契约。
- [ ] 移除 SCSS 包导入中的 Webpack `~` 前缀。
- [ ] 清理无效的 `webpackChunkName` 注释，重新确认懒加载和分包结果。
- [ ] 将 `serve`、`build`、`lint` 脚本从 `vue-cli-service` 迁出。
- [ ] 研究生产代码混淆是否需要保留；如保留，改成 Vite/Rollup 兼容方案。
- [ ] 更新 README 和安装脚本，删除 `--openssl-legacy-provider`。
- [ ] 不更新系统软件；只允许修改项目依赖。

## 不在本次范围

- [ ] 不迁移 Vue 3。
- [ ] 不重构业务 UI、主题、动画、路由权限或 API。
- [ ] 不替换 Vue Router、Vuex、Vue I18n、Axios。
- [ ] 不改变后端接口、认证 token 和 hash 路由行为。
- [ ] 不删除 `packages/*` 下的可组合 UI 工作区包及其测试。

## 重点风险

- Vue 2 官方 Vite 插件要求 Vue 2.7，需要先确认升级影响。
- SVG sprite 当前依赖 Webpack loader，是最明确的专属构建点。
- `src/settings.js`、`require.context`、`process.env.VUE_APP_BASE_API` 不能直接沿用。
- 现有 `webpack-obfuscator` 不能直接迁移到 Vite。
- 工作区源码别名可能造成重复 Vue 实例，需要检查 `resolve.dedupe`。
- 安装脚本依赖 `dist/`，迁移后必须保持目录兼容。

## 最低验收

- [ ] 以下命令不带 OpenSSL legacy 参数并通过：

  ```bash
  npm run lint -- --no-fix
  npm run test:ui-libraries
  npm run build:ui-labs
  npm run build
  npm run test:live-stack:e2e
  ```

- [ ] 模拟后端 `18081` 与前端 `18888` 可正常启动。
- [ ] 登录、导航、系统配置、三种订阅模板编辑器和移动端导航可正常使用。
- [ ] 浏览器控制台无模块加载、SVG、动态 chunk 和重复 Vue 错误。
- [ ] `/api/*` 代理行为与迁移前一致。
- [ ] UI 子模块提交后，在父仓库提交新的子模块指针。

## 给执行会话的提示词

```text
请在 /home/lh/git/trojanpanel-fork 当前分支上研究并执行 Vite 迁移，
以 /home/lh/git/trojanpanel-fork/docs/web-ui/Vite迁移TODO交接.md 为范围和验收依据。
先完成技术研究再实施；不要更新系统软件、迁移 Vue 3 或顺带重构业务 UI。
完成后运行现有 UI 库测试、生产构建和本地全栈 E2E，并提交 UI 子模块及父仓库指针。
```

---
