# Vite 迁移研究与实施

> 已完成的独立构建工具迁移记录；对应[迁移交接](Vite迁移TODO交接.md)。2026-09-01从web-ui目录移入本目录，保留历史研究与验收证据。

## 2026-08-30 技术选择

- 范围按 Vite迁移TODO交接.md；父仓库、UI 和安装脚本子模块均使用 codex/vite-migration。现有 UI 清理单独保存为 UI 提交 4bea1d6，未回退任何已完成 UI。
- 选择 Vue 2.7.16 + @vitejs/plugin-vue2 2.3.4 + Vite 7.3.6。npm registry 实查插件 peer range 到 Vite 7，未声明支持 Vite 8，因此不越过兼容范围。当前 Node 22.23.2 满足 Vite 的 ^20.19.0 || >=22.12.0；不更新系统软件。
- Vue 2.7 自带 vue/compiler-sfc；清理测试改用此编译器，移除 vue-template-compiler 和 Vue CLI Babel 配置。测试所需 Babel core 与 CommonJS transform 改为显式开发依赖。工作区 peer Vue ^2.6.11 已接受 2.7，继续保持兼容范围与源码别名，并 dedupe Vue。
- index.html 移到根目录，环境变量改用 import.meta.env，settings 改为 ESM。开发默认端口 8888，验收端口 18888；/api 路径原样代理到后端，原配置的删除 /api 再添加 /api 效果相同。
- dist/static 与 hash 路由不变；Rollup 分离 framework/dependencies，保留动态路由导入。沿用 javascript-obfuscator，通过仅构建启用的 renderChunk 混淆应用 chunk，排除 vendor chunk。混淆仅是既有发布行为，不作为安全边界。
- 保留内联 SVG AppIcon 及工作区资源包；旧 Sprite 资源已检索无生产引用后清理。SCSS 仅移除 Webpack ~ 包前缀，不改变业务样式。
- 继续使用 Yarn Classic lock；CI 改用 Node 22、取消 ignore-engines 与 OpenSSL legacy 参数；安装脚本仅改项目构建命令，不执行部署。

## 依据

- [Vue 2.7 官方迁移指南](https://v2.vuejs.org/v2/guide/migration-vue-2-7)
- [官方 Vue 2 Vite 插件依赖](https://github.com/vitejs/vite-plugin-vue2/blob/main/package.json)
- [Vite 构建配置](https://vite.dev/config/build-options)
- npm view @vitejs/plugin-vue2 version peerDependencies / npm view vite@7 version engines（2026-08-30 本机实查）

Vue 2 已结束官方常规维护，本次限定不迁移 Vue 3；迁移构建工具不改变这一上游维护风险。

## 2026-08-31 验收与复查

- 按用户要求删除旧 Vite 分支，从父仓库重构提交 da6feee、UI 重构提交 4bea1d6 重新创建 codex/vite-migration；安装脚本子模块使用同名分支，基准 694ce82。UI 与安装脚本两份 stash 恢复后逐项核对一致，均已删除。
- 使用 ES2021 的 ESLint 原生解析器，清理旧 globalThis 声明。Vue 2.7 编译器运行全部 10 项 UI 清理测试通过。
- 浏览器验收发现已有 LiquidTable 在异步请求前接收 null 时直接访问 length；先通过真实 Vue VNode 回归测试复现，再添加一行空值判断，保留原空表行为；不改业务页面、交互或样式。
- 本机 Node 22.23.2；所有验收未设置 OpenSSL legacy 参数。Yarn Classic frozen-lockfile 安装通过；npm ls vue --all 确认工作区和插件共用 Vue 2.7.16。
- npm run lint -- --no-fix、npm run test:ui-libraries（7 个包的契约/构建/exports/pack 及架构约束）、npm run test:ui-cleanup（10/10）、npm run build:ui-labs、npm run build 均通过，生产构建约 4.4 秒。
- npm run test:vite-proxy 通过：真实 Vite 服务连接临时回显后端，验证 /api 路径、编码 query、POST 方法与 body、Authorization 和后端 422 状态均保持。
- npm run test:live-stack:e2e 在 18888 开发服务和 18889 生产预览均通过，连接 18081 mock API；覆盖模拟账号登录、仪表板、系统配置、Clash.Meta / sing-box / Xray 模板输入与 JSON 格式化、客户端切换状态保留、390px 手机导航及控制台错误检查。生产少一个本地角色切换按钮符合 import.meta.env.DEV 预期。
- E2E 修正了旧测试遗漏 mock 验证码字段的问题；仅使用非空模拟输入，不处理真实验证码。编辑通过 WebDriver 全选替换，避免 clear/blur 重新填入旧内容。
- dist/index.html 仅预加载框架与第三方依赖，路由仍通过动态 import 加载；无 source map，保留混淆应用 chunk。安装脚本通过 bash -n；CI 配置静态复查通过，未触发远程 CI/镜像发布。

### 保留的限制

- Vue 2 已 EOL；官方插件支持范围截至 Vite 7，未升级 Vue 3 或使用不在 peer range 中的 Vite 8。
- Sass 构建提示现有 @import 弃用，当前构建成功；不在本次重写样式。开发控制台原有重复路由名 index 的 warning 保留，因为交接要求不改变路由。没有模块/SVG/chunk/重复 Vue 实例错误。
- 全栈验收后端为仓库 mock，不代表真实数据库、节点连接或生产部署已验证。
- 截图：/tmp/tp-composable-ui-live.png、/tmp/tp-vite-production-mobile.png（临时文件）。

- 补充验收：`npm run test:ui-labs:e2e` 通过 frosted/flat 材质切换、motion 接口和 Minimal Lab 独立布局验证。
