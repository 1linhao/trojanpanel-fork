# Web UI 功能与 API 接口映射

本文档是重构起点的接口索引，保留作查找入口；“当前”“已用/未用”和数量统计指编写时快照，不保证涵盖后续 UI 调整。修改接口前重新核对 `trojan-panel-ui/src/api`、Go 路由、DTO/VO 和权限迁移。现行 UI 状态见 [README](README.md)。

## 1. 调用约定

- 前端 API 基址：`VUE_APP_BASE_API=/api`。
- 下表路径均写完整浏览器请求路径，如 `/api/auth/login`。
- 登录后的请求头：`Authorization: Bearer <token>`。
- 普通 JSON 成功响应：`{ "code": 20000, "type": "success", "message": "", "data": ... }`。
- 业务失败仍通常返回 HTTP 200，由 `code` 判断；`50008`、`50014`、`50401` 会触发前端退出登录流程。
- GET 参数放 query；普通 POST 参数放 JSON；导入/上传使用 `multipart/form-data`。
- 下载接口返回 Blob/文件流，不使用 JSON 包装。订阅内容接口也直接返回文本、JSON 或 YAML。
- 分页公共入参：`pageNum`（从 1 开始）、`pageSize`，可选 `startTime`、`endTime`；分页响应一般含 `pageNum`、`pageSize`、`total`，但集合字段名因模块不同而不同。

## 2. 页面级映射

| 页面/路由 | UI 功能 | 直接依赖的 API | 前端角色 |
|---|---|---|---|
| 登录 `/login` | 系统名、开放注册、验证码、登录 | `GET /api/auth/setting`、`GET /api/auth/generateCaptcha`、`POST /api/auth/login` | 游客 |
| 注册 `/register` | 注册开关/验证码、提交注册、返回登录 | `GET /api/auth/setting`、`GET /api/auth/generateCaptcha`、`POST /api/auth/register` | 游客 |
| 全局框架 | 侧栏 Logo/系统名、当前用户、退出 | `GET /api/image/logo`、`GET /api/auth/setting`、`GET /api/account/getAccountInfo`、`POST /api/account/logout` | 已登录 |
| 仪表板 `/dashboard/index` | 用户/节点/系统指标、流量排行、服务器流量明细 | `GET /api/dashboard/panelGroup`、`GET /api/dashboard/trafficRank`、`GET /api/dashboard/serverTrafficUsage`、`GET /api/nodeServer/selectNodeServerList`、`GET /api/auth/setting` | 全部已登录；服务器流量表为管理功能 |
| 个人资料 `/modify/index` | 修改密码、用户名/邮箱 | `GET /api/auth/setting`、`POST /api/account/updateAccountPass`、`POST /api/account/updateAccountProperty` | 全部已登录 |
| 账号管理 `/account-manage/account-list` | 查询、新建、编辑、删除、重置流量、批量创建、导入/导出、未使用账号导出、复制用户订阅 | account、role、setting、fileTask 模块相关接口 | 前端：`sysadmin/admin` |
| 节点管理 `/node-manage/node-list` | 查询、详情、新建、编辑、删除、默认密钥、服务器/类型选项、订阅导出 | node、nodeType、nodeServer、account export 接口 | 全部已登录；写操作按钮按权限隐藏 |
| 服务器管理 `/server-manage/server-list` | 查询、详情、新建、编辑、删除、导入/导出、模板下载 | nodeServer、fileTask 接口 | 前端：`sysadmin/admin` |
| 服务器详情 `/server-manage/server-detail` | CPU、内存、磁盘状态 | `GET /api/nodeServer/nodeServerState` | 前端：`sysadmin/admin` |
| 内核升级 `/server-manage/kernel-upgrade` | 版本目录、节点库存、创建/查询/重试任务、mTLS 探测 | 7 个 kernel 接口及服务器查询接口 | `sysadmin` |
| 邮件记录 `/emailManage/email-record` | 分页、收件人/状态筛选 | `GET /api/emailRecord/selectEmailRecordPage` | 前端：`sysadmin/admin` |
| 文件任务 `/taskManage/task-list` | 分页、筛选、下载任务产物 | `GET /api/fileTask/selectFileTaskPage`、`POST /api/fileTask/downloadFileTask` | `sysadmin` |
| 系统配置 `/system/base-config` | 账号、邮件、面板设置、订阅模板；Logo/系统名称位于面板设置 | system 模块接口 | `sysadmin` |
| 黑名单 `/system/black-list` | 分页、新增、删除 | blackList 模块接口 | `sysadmin` |

## 3. 完整接口目录

“接入”列：`已用` 表示当前生产页面调用；`封装未用` 表示前端已有函数但当前页面没有调用；`直接资源` 表示模板直接使用 URL；`后端仅有` 表示没有对应前端封装。

### 3.1 游客、认证与全局资源

| 功能 | 方法与路径 | 入参 | `data`/响应 | 接入 |
|---|---|---|---|---|
| 登录 | `POST /api/auth/login` | JSON：`username`、`pass`、可选 `captchaId`、`captchaCode` | `{ token }` | 已用 |
| 注册 | `POST /api/auth/register` | JSON：`username`、`pass`、可选验证码字段 | `null` | 已用 |
| 公共设置 | `GET /api/auth/setting` | 无 | `{ registerEnable, registerQuota, registerExpireDays, trafficRankEnable, captchaEnable, emailEnable, systemName }` | 已用 |
| 生成验证码 | `GET /api/auth/generateCaptcha` | 无；前端封装尾部多写了 `/`，Gin 会重定向/规范化 | `{ captchaId, captchaImg }`，图片为 data URL/base64 内容 | 已用 |
| Logo | `GET /api/image/logo` | 无 | PNG 文件流 | 直接资源；`getLogo()` 封装未用 |
| 获取订阅内容 | `GET /api/auth/subscribe/:token` | path：base64url 连接密码；query：`client`、`template` | sing-box JSON、Clash YAML 或 v2ray/shadowrocket 文本 | 后端仅有；由订阅 URL 被客户端调用 |

注册和登录字段约束：用户名/密码 6–20 位字母数字；注册用户名不得包含 `admin`。验证码是否必填由系统配置控制，不能由新 UI 自行推断。

### 3.2 账号与订阅导出

| 功能 | 方法与路径 | 入参 | `data`/响应 | 接入 |
|---|---|---|---|---|
| 退出登录 | `POST /api/account/logout` | 无 | `null` | 已用 |
| 当前用户 | `GET /api/account/getAccountInfo` | 无 | `{ id, username, roles[] }` | 已用 |
| 账号分页 | `GET /api/account/selectAccountPage` | 分页；可选 `username`、`deleted:0/1`、`lastLoginTime:0/1`、`orderFields`、`orderBy:asc/desc` | `{ accounts[], pageNum, pageSize, total }` | 已用 |
| 账号详情 | `GET /api/account/selectAccountById` | query：`id` | `AccountVo` | 封装未用；列表直接使用行数据编辑 |
| 新建账号 | `POST /api/account/createAccount` | `username, pass, roleId(2/3), email?, expireTime, deleted(0/1), quota` | `null` | 已用 |
| 编辑账号 | `POST /api/account/updateAccountById` | `id, username, pass?, roleId(1/2/3), email?, expireTime, deleted, quota` | `null` | 已用 |
| 删除账号 | `POST /api/account/deleteAccountById` | `{ id }` | `null` | 已用 |
| 修改本人密码 | `POST /api/account/updateAccountPass` | `{ oldPass, newPass }` | `null` | 已用 |
| 修改本人资料 | `POST /api/account/updateAccountProperty` | `{ username?, email?, pass }`；`pass` 为确认密码 | `null` | 已用 |
| 重置账号流量 | `POST /api/account/resetAccountDownloadAndUpload` | `{ id }` | `null` | 已用 |
| 批量创建账号 | `POST /api/account/createAccountBatch` | `{ num:5..500, presetExpire:1..365, presetQuota:-1..1024000 }` | `null`，异步生成文件任务 | 已用 |
| 导出账号 | `POST /api/account/exportAccount` | 无 | `null`，异步文件任务 | 已用 |
| 导出未使用账号 | `POST /api/account/exportAccountUnused` | 无 | `null`，异步文件任务 | 已用 |
| 导入账号 | `POST /api/account/importAccount` | multipart：`file`（JSON，最大 10MB）、`cover` | `null`，异步文件任务 | 已用 |
| 客户端导出选项 | `GET /api/account/exportOptions` | 无 | `[{ id, name, templates:[{id,name}], formats[] }]` | 已用 |
| 生成订阅地址 | `GET /api/account/exportSubscribe` | query：可选 `id`、必填 `client`、`template` | 相对订阅路径字符串 | 已用 |
| 生成订阅二维码 | `GET /api/account/exportQRCode` | 同上；仅 `v2ray`/`shadowrocket` | PNG 的 base64 字符串 | 已用 |

客户端/模板合法组合：`sing-box + tun|outbound`、`clash-meta + default`、`v2ray + default`、`shadowrocket + default`。管理员可带 `id` 为指定账号导出，普通用户只能导出自己。

账号列表主要返回字段：`id, username, email, roleId, deleted, quota, download, upload, presetExpire, presetQuota, lastLoginTime, expireTime, createTime, roles[]`。流量单位是 byte；旧页面编辑时会转换成 MB，新 UI 必须明确显示/提交单位。

### 3.3 仪表板

| 功能 | 方法与路径 | 入参 | `data` | 接入 |
|---|---|---|---|---|
| 概览指标 | `GET /api/dashboard/panelGroup` | 无 | `{ quota, residualFlow, nodeCount, expireTime, accountCount, cpuUsed, memUsed, diskUsed }`；字段随角色有意义 | 已用 |
| 账号流量排行 | `GET /api/dashboard/trafficRank` | query：可选 `period=total|month|day` | `[{ username, upload, download, trafficUsed }]` | 已用 |
| 服务器流量明细 | `GET /api/dashboard/serverTrafficUsage` | 分页；`period=total|year|month|day`；可选 `nodeServerId` | `{ rows:[{ accountId, username, nodeServerId, nodeServerName, upload, download, total }], pageNum, pageSize, total }` | 已用 |

### 3.4 节点

| 功能 | 方法与路径 | 入参 | `data` | 接入 |
|---|---|---|---|---|
| 节点分页 | `GET /api/node/selectNodePage` | 分页；可选 `name`、`nodeServerId` | `{ nodes[], pageNum, pageSize, total }` | 已用 |
| 管理详情 | `GET /api/node/selectNodeById` | query：`id` | 完整 `NodeOneVo` | 已用（编辑） |
| 用户连接详情 | `GET /api/node/selectNodeInfo` | query：`id` | 完整连接参数和凭据 | 已用（详情） |
| 新建节点 | `POST /api/node/createNode` | `NodeCreateDto`，见下方字段族 | `null` | 已用 |
| 编辑节点 | `POST /api/node/updateNodeById` | `NodeUpdateDto`；比新建多 `id, nodeSubId` | `null` | 已用 |
| 删除节点 | `POST /api/node/deleteNodeById` | `{ id }` | `null` | 已用 |
| 生成节点二维码 | `POST /api/node/nodeQRCode` | `{ id }` | 二维码内容 | 封装未用（当前改走账号订阅二维码） |
| 生成节点 URL | `POST /api/node/nodeURL` | `{ id }` | 节点 URL 字符串 | 封装未用 |
| 节点默认密钥 | `GET /api/node/nodeDefault` | 无 | `{ publicKey, privateKey, shortId, spiderX }` | 已用（新建 Reality） |
| 节点类型选项 | `GET /api/nodeType/selectNodeTypeList` | 无 | `[{ id, name }]` | 已用 |

节点通用字段：`nodeServerId, nodeTypeId, name, domain, port, priority, clients[]`。`clients` 可选 `sing-box|clash-meta|v2ray|shadowrocket`。协议字段族包括：

- Xray：`xrayProtocol, xrayFlow, xraySSMethod, xrayUotEnable, xrayUotVersion, xrayXudpEnable, xrayMuxEnable, realityPbk, xraySettings, xrayStreamSettings, xrayTag, xraySniffing, xrayAllocate`。
- Trojan-Go：`trojanGoSni, trojanGoMuxEnable, trojanGoWebsocketEnable, trojanGoWebsocketPath, trojanGoWebsocketHost, trojanGoSsEnable, trojanGoSsMethod, trojanGoSsPassword`。
- Hysteria：`hysteriaProtocol, hysteriaObfs, hysteriaUpMbps, hysteriaDownMbps, hysteriaServerName, hysteriaInsecure, hysteriaFastOpen`。
- Hysteria 2：`hysteria2ObfsPassword, hysteria2UpMbps, hysteria2DownMbps, hysteria2ServerName, hysteria2Insecure, hysteria2PortHopping, hysteria2HopInterval`。
- NaiveProxy：`naiveUotEnable, naiveUotVersion`。

新 UI 不应把所有协议字段同时设为必填；应按 `nodeTypeId` 和协议组合构造 payload，并复用后端 DTO 约束。

### 3.5 节点服务器

| 功能 | 方法与路径 | 入参 | `data`/响应 | 接入 |
|---|---|---|---|---|
| 服务器分页 | `GET /api/nodeServer/selectNodeServerPage` | 分页；可选 `name`、`ip` | `{ nodeServers[], pageNum, pageSize, total }` | 已用 |
| 服务器下拉 | `GET /api/nodeServer/selectNodeServerList` | 可选 `name`、`ip` | `[{ id, name }]` | 已用 |
| 服务器详情 | `GET /api/nodeServer/selectNodeServerById` | query：`id` | `NodeServerOneVo` | 已用 |
| 运行状态 | `GET /api/nodeServer/nodeServerState` | query：`id` | `{ cpuUsed, memUsed, diskUsed }` | 已用 |
| 新建服务器 | `POST /api/nodeServer/createNodeServer` | 见下方服务器写入字段 | `null` | 已用 |
| 编辑服务器 | `POST /api/nodeServer/updateNodeServerById` | 写入字段 + `id` | `null` | 已用 |
| 删除服务器 | `POST /api/nodeServer/deleteNodeServerById` | `{ id }` | `null` | 已用 |
| 导出服务器 | `POST /api/nodeServer/exportNodeServer` | 无 | `null`，异步文件任务 | 已用 |
| 导入服务器 | `POST /api/nodeServer/importNodeServer` | multipart：`file`（JSON，最大 10MB）、`cover` | `null`，异步文件任务 | 已用 |

服务器写入字段：`name, ip, grpcPort, grpcTlsServerName, trafficPeriod(none|day|month|year), trafficLimitMode(combined|separate), trafficTotalLimit, trafficUploadLimit, trafficDownloadLimit`。返回还包含 `grpcTLSMode, trafficStatus, status, trojanPanelCoreVersion, kernelSummary, createTime`；流量限额均为 byte。

### 3.6 内核升级

| 功能 | 方法与路径 | 入参 | `data` | 接入 |
|---|---|---|---|---|
| 版本目录 | `GET /api/kernel/releases` | `kernel=xray|hysteria2`、`channel=stable|prerelease`、可选 `refresh` | release catalog | 已用 |
| 节点库存 | `GET /api/kernel/inventory` | `nodeServerId` | 当前内核/版本库存 | 已用 |
| 创建升级任务 | `POST /api/kernel/createTask` | `{ nodeServerIds[], canaryNodeServerId?, targets:[{kernel,version,channel,action?}] }` | 创建后的任务 | 已用 |
| 任务分页 | `GET /api/kernel/selectTaskPage` | 分页；可选 `status=queued|running|succeeded|partial|failed` | `{ tasks[], pageNum, pageSize, total }` | 已用 |
| 任务详情 | `GET /api/kernel/selectTaskById` | `id` | task + `items[]` | 已用 |
| 重试任务 | `POST /api/kernel/retryTask` | `{ id, itemIds?[] }` | `null` | 已用 |
| 探测并启用 mTLS | `POST /api/kernel/probeMTLS` | `{ nodeServerId, serverName }` | `null` | 已用 |

任务主要字段：`id, operatorId, operatorName, canaryNodeId, status, createdAt, updatedAt, items[]`；item 含 `nodeServerId, kernel, fromVersion, targetVersion, channel, action, stage, result, error, rollbackResult, attempt` 等。

### 3.7 系统、角色、黑名单、邮件、文件任务

| 功能 | 方法与路径 | 入参 | `data`/响应 | 接入 |
|---|---|---|---|---|
| 完整系统配置 | `GET /api/system/selectSystemByName` | 无 | `SystemVo` | 已用 |
| 更新系统配置 | `POST /api/system/updateSystemById` | 完整 `SystemUpdateDto`，不是局部 PATCH | `null` | 已用 |
| 上传 Web 文件 | `POST /api/system/uploadWebFile` | multipart：`file`，ZIP，最大 10MB | `null` | 已用 |
| 上传 Logo | `POST /api/system/uploadLogo` | multipart：`file`，PNG，最大 3MB | `null` | 已用 |
| 角色下拉 | `GET /api/role/selectRoleList` | 可选 `name`、`desc` | `[{ id, name, desc }]` | 已用 |
| 黑名单分页 | `GET /api/blackList/selectBlackListPage` | 分页；可选 `ip` | `{ blackLists[], pageNum, pageSize, total }` | 已用 |
| 添加黑名单 | `POST /api/blackList/createBlackList` | `{ ip }`，IP 或 FQDN，不能为 `127.0.0.1` | `null` | 已用 |
| 删除黑名单 | `POST /api/blackList/deleteBlackListByIp` | `{ ip }` | `null` | 已用 |
| 邮件记录分页 | `GET /api/emailRecord/selectEmailRecordPage` | 分页；可选 `toEmail`、`state=-1|0|1` | `{ emailRecords[], pageNum, pageSize, total }` | 已用 |
| 文件任务分页 | `GET /api/fileTask/selectFileTaskPage` | 分页；可选 `type=0..4`、`accountUsername` | `{ fileTasks[], pageNum, pageSize, total }` | 已用 |
| 下载任务产物 | `POST /api/fileTask/downloadFileTask` | `{ id }` | 文件流；任务必须成功且文件存在 | 已用 |
| 删除文件任务 | `POST /api/fileTask/deleteFileTaskById` | `{ id }` | `null` | 封装未用，当前页面没有删除按钮 |
| 下载导入模板 | `POST /api/fileTask/downloadTemplate` | `{ id:1 }` 账号模板；`{ id:2 }` 服务器模板 | JSON 文件流 | 已用 |

完整系统配置字段分组：

- 账号：`registerEnable, registerQuota, registerExpireDays, resetDownloadAndUploadMonth, trafficRankEnable, captchaEnable`。
- 邮件：`expireWarnEnable, expireWarnDay, emailEnable, emailHost, emailPort, emailUsername, emailPassword`。
- 外观/客户端模板：`systemName, clashRule, singBoxTun, singBoxOutbound, xrayTemplate` 及四个对应模板名称字段。

`updateSystemById` 会校验整份 DTO；重构时即使只编辑一个 Tab，也要先保留并回传其他配置字段，避免被空值覆盖或校验失败。

## 4. 权限事实与重构风险

### 4.1 公共与鉴权边界

`/api/auth/*` 和 `/api/image/logo` 在 JWT/Casbin 中间件之前注册，属于公共接口。其余 `/api/*` 均先经过 JWT 和 Casbin。

### 4.2 当前权限来源不止初始化 SQL

- 基础 `v2.3.0.sql` 主要写入 `sysadmin` 和 `user` 规则。
- 程序启动迁移会为 `sysadmin/admin/user` 补写三个订阅导出 GET 权限。
- 程序启动迁移会为 `sysadmin/admin` 补写 `serverTrafficUsage`。
- 程序启动迁移会为 `sysadmin` 补写全部 kernel 权限。

因此重构和联调必须以运行数据库中的 `casbin_rule` 为准，不能只依据 SQL 文件。尤其要核对 `admin`：前端允许其进入账号、服务器和邮件页面，但初始化 SQL 没有为大多数相应接口直接写 `admin` 规则；如果部署库未另行补齐，会出现“菜单可见但接口 50403/Forbidden”。

### 4.3 前端当前未接入/遗留差异

- 64 个前端 API 封装中，`selectAccountById`、`nodeQRCode`、`nodeURL`、`deleteFileTaskById`、`getLogo` 当前没有被生产页面函数调用。
- 后端有 `GET /api/auth/subscribe/:token`，前端不通过 Axios 调用，而是把生成的 URL 交给客户端。
- `api/node.go` 还保留未注册路由的 `ExportNode`/`ImportNode` 处理函数，不能作为可用 Web API。
- 初始化 Casbin 仍包含旧路径 `clashSubscribe`/`clashSubscribeForSb`，当前路由已改为 `exportOptions`/`exportSubscribe`/`exportQRCode`；启动迁移会补新权限，但旧规则是遗留项。

## 5. 建议的整站重构接入边界

- 建立统一 API client：集中处理 baseURL、Bearer Token、业务 `code`、Blob、取消请求和超时，不在页面重复判断。
- 为每个表格统一 `{ rows, total, pageNum, pageSize }` 的前端适配层；后端集合字段名目前有 `accounts/nodes/nodeServers/emailRecords/fileTasks/blackLists/tasks/rows` 多种形式。
- 将 DTO 类型与页面表单模型分离，提交前做显式转换，尤其是 byte/MB、毫秒时间戳、`0/1` 布尔值及协议 JSON 字符串。
- 页面权限与接口权限共用同一份能力表；不要仅依靠路由 `roles` 或隐藏按钮。
- 对上传/下载、订阅原始响应单独建 transport，避免经过只接受 `{code:20000}` 的 JSON 响应解析。
- 注册入口问题已关闭，见同目录 [TODO.md](TODO.md) 的 WEB-001 完成记录；不再作为待修复事项。

## 6. 代码依据

- 前端页面路由：`trojan-panel-ui/src/router/index.js`
- 前端 API 封装：`trojan-panel-ui/src/api/*.js`
- Axios 约定：`trojan-panel-ui/src/utils/request.js`
- 后端路由：`trojan-panel/router/*.go`
- 请求/响应模型：`trojan-panel/model/dto/*.go`、`trojan-panel/model/vo/*.go`
- 权限与启动迁移：`trojan-panel/middleware/casbin_rbac.go`、`trojan-panel/dao/mysql.go`
