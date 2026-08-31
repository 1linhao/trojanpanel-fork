# 文档导航

整理日期：2026-09-01。当前实现以本分支源码为准；历史需求中的未勾选项不自动代表现有待办，发布记录也不代表当前线上状态。

## 当前开发入口

- [Web UI 当前状态与开发边界](web-ui/README.md)
- [Web UI 待办](web-ui/TODO.md)
- [Web UI 全页面检查](web-ui/全页面规范化检查.md)
- [节点适用客户端](node-client-visibility/需求理解.md)：已更新为四客户端实现说明。

## 设计与运维

- [可组合 UI 资源库方案](web-ui/可组合UI资源库重构方案.md)：目标架构与迁移原则，区分已实现和未迁移范围。
- [API 接口映射](web-ui/API接口映射.md)：重构起点的接口索引，修改接口前复核源码。
- 内核升级：[需求](kernel-upgrade/需求规格.md)、[设计](kernel-upgrade/设计说明.md)、[测试](kernel-upgrade/测试与验收.md)、[运维与回退](kernel-upgrade/运维与回退.md)。执行运维操作前重新确认目标、镜像和授权。
- 架构决策：[持久化版本目录与原子切换](adr/0001-持久化版本目录与原子切换.md)、[公网证书与内部客户端 CA](adr/0002-公网服务端证书与内部客户端CA.md)。

## 历史记录与参考

- 已完成的Vite迁移：[交接与完成记录](vite-migration/Vite迁移TODO交接.md)、[研究与实施](vite-migration/Vite迁移研究与实施.md)。独立于当前UI规范化任务，不需重做。
- 流量看板与额度：[需求](traffic-dashboard-quota/需求理解.md)、[设计](traffic-dashboard-quota/方案设计.md)、[审查](traffic-dashboard-quota/代码审查.md)、[生产部署记录](traffic-dashboard-quota/生产部署记录.md)。
- 历史排行与重置：[需求](traffic-history-reset/需求理解.md)、[设计](traffic-history-reset/方案设计.md)、[审查](traffic-history-reset/代码审查.md)。
- [内核升级实机发布记录](kernel-upgrade/实机发布记录-2026-07-30.md)。
- [Web UI 验证记录](web-ui/代码审查.md)：按时间追加，旧问题可能已在后续记录中关闭。
- [磨砂玻璃静态原型](web-ui/prototype-frosted-glass/README.md)：保留演示资源及其专用测试，不作为当前页面验收标准。

## 2026-09-01 清理

将两份已完成的Vite迁移文档从`web-ui/`移至`vite-migration/`，保留全文与验收证据，修正关联导航；UI待办、覆盖表、审查、架构/API参考及原型保留。未删除业务源码、原型资源或测试。当前20项UI待修复不变。

`docs/`默认被忽略；提交此次目录整理时，需显式纳入迁移后的新路径，避免只提交旧路径删除。本次状态保存纳入当前UI文档及两份Vite归档，不改变整个docs目录的忽略策略，也不新增跟踪其他任务资料或历史原型资源。

## 2026-08-30 清理记录

移除 5 份已被后续方案/实现替代的 UI 需求、液态玻璃交接/调研和阶段评审稿。仍有效的进展、交互约束和未迁移边界合并到 Web UI 当前状态页；没有删除架构决策、生产发布记录或业务源码。

当时本仓库默认忽略 `docs/`（旧位置的Vite交接单独跟踪），清理前已备份全部文档，不能仅依赖 Git 恢复未跟踪文件：

`/home/lh/.local/state/trojanpanel-doc-backups/cleanup-20260830-Gk4XWW/docs-before-cleanup.tar.gz`

恢复时从归档中提取所需文件，避免整包覆盖后来修改的文档。
