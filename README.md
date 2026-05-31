# op-knock

`op-knock` 是一个面向 OpenWRT 的网关和管理面板，用于私有服务暴露场景。它将反向代理、登录鉴权、SSL 证书、DDNS、IP 白名单、WAF 和隧道管理集成在同一个面板中。

> 本项目基于 [fn-knock](https://github.com/kci-lnk/fn-knock-turborepo) MIT 协议分叉改编，适配 OpenWRT 平台。

---

## 功能

- 反向代理：HTTP/HTTPS 转发、认证前置、访问日志
- 登录鉴权：管理后台、OIDC、Passkey、验证码
- SSL 证书：ACME 证书申请与管理
- 隧道集成：Cloudflared、frpc 配置与状态
- 安全防护：IP 白名单、WAF、登录退避
- 运维面板：系统监控、在线终端、运行日志

---

## 安装

### 1. 准备环境

OpenWRT / ImmortalWrt x86_64，确保以下依赖已安装：

```bash
opkg update
opkg install node redis-server
```

### 2. 下载 IPK

从 [Releases](https://github.com/xuu1998/op-knock/releases) 下载 `fn-knock_x.x.x_x86_64.ipk`，上传到路由器 `/tmp/`。

### 3. 安装

```bash
opkg install /tmp/fn-knock_1.7.0_x86_64.ipk
```

### 4. 启动服务

```bash
/etc/init.d/redis start
/etc/init.d/fn-knock start
/etc/init.d/fn-knock enable
```

### 5. 开放防火墙端口（如有必要）

```bash
uci add firewall rule
uci set firewall.@rule[-1].name='fn-knock'
uci set firewall.@rule[-1].src='wan'
uci set firewall.@rule[-1].dest_port='7999'
uci set firewall.@rule[-1].target='ACCEPT'
uci commit firewall
/etc/init.d/firewall restart
```

---

## 使用

安装完成后访问管理面板：

```
http://<路由器IP>:7999/admin/
```

首次登录需要设置管理员账号和密码。

### 常用命令

| 命令 | 说明 |
| --- | --- |
| `/etc/init.d/fn-knock start` | 启动服务 |
| `/etc/init.d/fn-knock stop` | 停止服务 |
| `/etc/init.d/fn-knock restart` | 重启服务 |
| `/etc/init.d/fn-knock status` | 查看状态 |
| `/etc/init.d/fn-knock enable` | 开机自启 |
| `/etc/init.d/fn-knock disable` | 关闭自启 |

### 端口说明

| 端口 | 用途 |
| --- | --- |
| 7996 | Go 网关管理 API（仅 127.0.0.1） |
| 7997 | 认证服务（仅 127.0.0.1） |
| 7998 | 后端管理 API（仅 127.0.0.1） |
| 7999 | 反向代理入口 + 管理面板 |

---

## 仓库结构

| 路径 | 说明 |
| --- | --- |
| `apps/server-admin` | Node.js / Elysia 后端 |
| `apps/server-admin-view` | Vue 管理前端 |
| `apps/server-auth-view` | 认证页前端 |
| `apps/fn-knock-openwrt` | OpenWRT IPK 打包脚本与配置 |
| `packages/admin-shared` | 管理端共享组件 |
| `packages/frontend-core` | 前端共享 API、认证工具 |
| `packages/ui-vue` | Vue UI 基础组件 |

---

## 从源码构建

需要 Node.js >= 18 和 WSL（Windows）或 Linux 环境。

```bash
# 安装依赖
npm install

# 编译后端
npm run build -w apps/server-admin

# 编译前端
npm run build -w apps/server-admin-view
npm run build -w apps/server-auth-view

# 构建 OpenWRT IPK
bash apps/fn-knock-openwrt/scripts/build-ipk-final.sh
```

---

## 注意

- **Redis**：部分功能（登录态、配置存储、事件系统）需要 Redis 支持。没有 Redis 时服务仍可运行，但功能受限。
- **防火墙**：本项目不会修改 OpenWRT 已有的防火墙规则。所有宿主机防火墙操作在 OpenWRT 模式均已禁用。
- **更新**：OpenWRT 模式不支持应用内更新，请通过 `opkg upgrade` 升级。

---

## License

[MIT](./LICENSE)

Copyright (c) 2026 op-knock contributors.

Original work Copyright (c) 2026 KCI-LNK.
