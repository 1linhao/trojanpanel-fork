# Trojan Panel Workspace

这是 Trojan Panel 系列仓库的统一入口。各组件继续保留独立 Git 历史、分支和发布流程，本仓库通过 Git submodule 固定一组经过验证的组件版本。

## 组件仓库

| 目录 | 仓库 | 用途 |
| --- | --- | --- |
| `trojan-panel` | [1linhao/trojan-panel](https://github.com/1linhao/trojan-panel) | 后端管理服务 |
| `trojan-panel-ui` | [1linhao/trojan-panel-ui](https://github.com/1linhao/trojan-panel-ui) | Web 管理界面 |
| `trojan-panel-core` | [1linhao/trojan-panel-core](https://github.com/1linhao/trojan-panel-core) | 节点核心服务 |
| `trojan-panel-install-script` | [1linhao/trojan-panel-install-script](https://github.com/1linhao/trojan-panel-install-script) | 安装与升级脚本 |
| `trojanpanel.github.io` | [1linhao/trojanpanel.github.io](https://github.com/1linhao/trojanpanel.github.io) | 项目站点 |

## 获取完整工作区

稳定主线：

```bash
git clone --recurse-submodules git@github.com:1linhao/trojanpanel-fork.git
```

磨砂玻璃 Web 分支：

```bash
git clone --branch codex/frosted-glass-ui --recurse-submodules \
  git@github.com:1linhao/trojanpanel-fork.git
```

已有工作区同步组件版本：

```bash
git pull
git submodule sync --recursive
git submodule update --init --recursive
```

## 分支约定

- `main`：源 UI 基线与稳定组件组合。
- `codex/frosted-glass-ui`：磨砂玻璃 Web UI、性能优化及其对应组件组合。

组件代码仍在各自仓库中提交和发布；组件提交完成后，再更新本仓库中的 submodule 指针，以记录可复现的整套版本。
