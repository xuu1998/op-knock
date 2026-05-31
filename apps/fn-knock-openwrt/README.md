# fn-knock OpenWRT IPK Package

## 概述

fn-knock OpenWRT 移植版，将 fn-knock 网关和管理面板适配到 OpenWRT/ImmortalWRT 路由器平台。

## 支持的平台

- **架构**: x86_64 (amd64), aarch64 (arm64)
- **系统**: OpenWRT 21.02+, ImmortalWRT 23.05+, 24.10+
- **依赖**: Node.js >= 18, Redis

## 目录结构

```
fn-knock-openwrt/
├── files/                          # IPK 包文件结构
│   ├── CONTROL/                    # 包控制文件
│   │   ├── control                 # 包元数据
│   │   ├── conffiles               # 配置文件列表
│   │   ├── preinst                 # 安装前脚本
│   │   ├── postinst                # 安装后脚本
│   │   ├── prerm                   # 卸载前脚本
│   │   └── postrm                  # 卸载后脚本
│   ├── etc/
│   │   ├── config/fn-knock         # UCI 配置文件
│   │   └── init.d/fn-knock         # 服务启动脚本
│   └── usr/lib/fn-knock/           # 应用程序文件
│       ├── server/                 # Go 网关二进制
│       ├── server-admin/           # Node.js 后端
│       ├── server-auth-view/       # 认证页前端
│       └── ui/www/                 # 管理面板前端
├── scripts/
│   └── build-ipk.sh                # IPK 打包脚本
└── Makefile                        # OpenWRT SDK Makefile
```

## 构建方式

### 方式一：使用打包脚本（推荐）

1. **准备环境**
   ```bash
   # 在开发机器上
   cd fn-knock-turborepo
   npm install
   ```

2. **准备 Node.js 运行时（可选）**
   ```bash
   # 下载 Node.js for Linux x64
   mkdir -p apps/fn-knock-openwrt/nodejs-bundle
   cd apps/fn-knock-openwrt/nodejs-bundle
   wget https://nodejs.org/dist/v20.11.0/node-v20.11.0-linux-x64.tar.gz
   tar xzf node-v20.11.0-linux-x64.tar.gz --strip-components=1
   rm node-v20.11.0-linux-x64.tar.gz
   ```

3. **执行打包**
   ```bash
   bash apps/fn-knock-openwrt/scripts/build-ipk.sh
   ```

4. **输出**
   ```
   dist/fn-knock_1.7.0_x86_64.ipk
   ```

### 方式二：使用 OpenWRT SDK

1. **将 Makefile 复制到 OpenWRT SDK**
   ```bash
   cp apps/fn-knock-openwrt/Makefile <openwrt-sdk>/package/fn-knock/
   ```

2. **编译**
   ```bash
   make package/fn-knock/compile V=s
   ```

3. **输出**
   ```
   <openwrt-sdk>/bin/packages/<arch>/base/fn-knock_1.7.0-1_<arch>.ipk
   ```

## 安装

### 方法一：通过 SCP + opkg

```bash
# 传输到路由器
scp dist/fn-knock_1.7.0_x86_64.ipk root@192.168.1.1:/tmp/

# SSH 到路由器安装
ssh root@192.168.1.1
opkg install /tmp/fn-knock_1.7.0_x86_64.ipk
```

### 方法二：通过 LuCI

1. 登录 LuCI 管理界面
2. 导航到 **系统 > 软件包**
3. 点击 **上传软件包**
4. 选择 `fn-knock_1.7.0_x86_64.ipk` 并安装

## 使用

### 服务管理

```bash
# 启动服务
/etc/init.d/fn-knock start

# 停止服务
/etc/init.d/fn-knock stop

# 重启服务
/etc/init.d/fn-knock restart

# 查看状态
/etc/init.d/fn-knock status

# 开机自启
/etc/init.d/fn-knock enable

# 禁用开机自启
/etc/init.d/fn-knock disable
```

### 访问面板

安装完成后，通过浏览器访问：
```
http://<路由器IP>:7999
```

### 端口说明

| 端口 | 用途 |
|------|------|
| 7999 | 网关代理端口（主要访问入口） |
| 7998 | 后端管理 API |
| 7997 | 认证服务 |
| 7996 | Go 网关管理接口 |

### 配置

#### UCI 配置

编辑 `/etc/config/fn-knock`：
```
config fn-knock 'main'
    option enabled '1'
    option backend_port '7998'
    option auth_port '7997'
    option go_backend_port '7996'
    option proxy_port '7999'
    option node_bin '/usr/bin/node'
    option data_dir '/var/run/fn-knock'
```

#### 网关配置

编辑 `/etc/fn-knock/config.toml`：
```toml
[admin]
port = 7996

[proxy]
port = 7999
```

## 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `FN_KNOCK_OPENWRT` | 启用 OpenWRT 模式 | `1` (自动设置) |
| `FN_KNOCK_NODE_BIN` | Node.js 可执行文件路径 | `/usr/bin/node` |
| `BACKEND_PORT` | 后端 API 端口 | `7998` |
| `AUTH_PORT` | 认证服务端口 | `7997` |
| `GO_BACKEND_PORT` | Go 网关管理端口 | `7996` |
| `GO_REPROXY_PORT` | 网关代理端口 | `7999` |

## 功能差异

与飞牛 FPK / Docker 版本相比，OpenWRT 版本有以下功能限制：

| 功能 | FPK/Docker | OpenWRT | 说明 |
|------|------------|---------|------|
| 反向代理 | ✓ | ✓ | 核心功能完整 |
| 登录鉴权 | ✓ | ✓ | 完整支持 |
| SSL/ACME | ✓ | ✓ | 完整支持 |
| DDNS | ✓ | ✓ | 完整支持 |
| IP 白名单 | ✓ | ✓ | 通过 Go 网关实现 |
| WAF | ✓ | ✓ | 完整支持 |
| 隧道 (frp/cloudflared) | ✓ | ✓ | 完整支持 |
| 防火墙管理 | ✓ | ✗ | 请使用 OpenWRT 防火墙 |
| Smart Connect | ✓ | ✗ | 请使用 OpenWRT DNS |
| 系统时间同步 | ✓ | ✗ | 请使用 NTP |
| 应用内更新 | ✓ | ✗ | 请使用 opkg upgrade |
| Web 终端 | ✓ | ✓ | 完整支持 |

## 日志

服务日志存储在 `/var/run/fn-knock/info.log`：
```bash
# 查看实时日志
tail -f /var/run/fn-knock/info.log
```

## 故障排查

### Node.js 未找到

```bash
# 检查 Node.js 是否安装
which node
node --version

# 如果未安装
opkg update
opkg install node

# 或者设置自定义 Node.js 路径
export FN_KNOCK_NODE_BIN=/path/to/node
```

### Redis 未运行

```bash
# 检查 Redis 状态
/etc/init.d/redis status

# 启动 Redis
/etc/init.d/redis start
/etc/init.d/redis enable
```

### 端口冲突

```bash
# 检查端口占用
netstat -tlnp | grep -E '7996|7997|7998|7999'

# 修改端口（编辑 UCI 配置）
uci set fn-knock.main.proxy_port=8999
uci commit fn-knock
/etc/init.d/fn-knock restart
```

## 卸载

```bash
opkg remove fn-knock
```

卸载后会清理：
- `/var/run/fn-knock/` 运行时数据
- `/etc/fn-knock/` 网关配置

## 开发

### 本地开发调试

```bash
cd fn-knock-turborepo
npm install
npm run dev
```

### 构建所有组件

```bash
npm run build
```

## 许可证

MIT License

## 支持

- GitHub: https://github.com/xuu1998/op-knock
