# Clash TUN 模式与 Tailscale 共存：完整排查与解决方案


## 问题描述

开启 Clash（mihomo 内核）的 TUN 模式后，无法访问 Tailscale 的 MagicDNS 域名（`*.ts.net`），Clash 日志报错：

```
[TCP] dial DIRECT (match DomainSuffix/ts.net) 127.0.0.1:60140 --> studio.tail7f8eb.ts.net:443 error: dns resolve failed: context deadline exceeded
```

环境信息：

- macOS（Darwin）
- Clash Party（mihomo-party），内核为 mihomo
- Tailscale，使用 MagicDNS

## 根因分析

这个问题的本质不是规则配置错误，而是 **mihomo 的 `auto-detect-interface` 机制与 Tailscale 的虚拟网卡冲突**。

### mihomo TUN 模式的工作原理

mihomo 开启 TUN 后，会创建一个虚拟网卡（如 `utun1500`）接管系统所有流量。为了防止自身出站流量再次被 TUN 拦截（回环），mihomo 会"保护"自己的出站连接——通过 `auto-detect-interface` 自动检测出站接口，将自身流量直接发往物理网卡（如 `en0`）。

### 问题出在哪

Tailscale 的设备通过虚拟网卡 `utun4`（编号可能不同）通信，IP 段为 `100.64.0.0/10`，MagicDNS 服务器地址为 `100.100.100.100`。这些地址**只能通过 Tailscale 的虚拟网卡访问**，物理网卡根本不可达。

但 mihomo 的 `auto-detect-interface` 不认识 Tailscale 的路由，**把所有出站流量（包括发往 `100.100.100.100` 的 DNS 查询）都检测到了 `en0`**：

```
[DNS] resolve studio.tail7f8eb.ts.net A from udp://100.100.100.100:53
[TUN] Auto detect interface for 100.100.100.100 --> en0  ← 错误！应该走 utun4
```

这导致了两个层面的故障：

1. **DNS 解析失败**：mihomo 通过 `en0` 向 `100.100.100.100` 发 DNS 查询 → 不可达 → 超时
2. **TCP 连接失败**：即使 DNS 解析成功，mihomo 通过 `en0` 向 Tailscale IP 发起 TCP 连接 → 同样不可达 → 超时

### 为什么系统命令正常但 Clash 不行

```bash
# 正常！普通进程走系统路由表，100.100.100.100 路由到 utun4
$ ping 100.100.100.100
64 bytes from 100.100.100.100: icmp_seq=0 ttl=64 time=0.943 ms

# 正常！
$ nslookup studio.tail7f8eb.ts.net 100.100.100.100
Name:    studio.tail7f8eb.ts.net
Address: 100.95.73.65
```

普通进程遵循系统路由表（`100.100.100.100/32 → utun4`），而 mihomo 为防 TUN 回环，绕过了路由表直接走 `en0`。

## 解决方案

核心思路：**不依赖 mihomo 的自动接口检测，显式指定 Tailscale 流量走 `utun4` 接口**。

### 第一步：确认 Tailscale 使用的网卡接口

```bash
$ ifconfig | grep -E "^utun|inet 100\."
utun4: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1280
	inet 100.70.0.1 --> 100.70.0.1 netmask 0xffffffff
```

记住这个接口名（本例为 `utun4`），后续配置需要用到。

> **注意**：macOS 上 Tailscale 的 utun 编号不固定，重启后可能变化。如果发现连接又断了，先检查接口编号是否变了。可以用以下命令自动获取：
>
> ```bash
> tailscale_iface=$(ifconfig | grep -B1 "inet 100\." | head -1 | cut -d: -f1)
> echo "当前 Tailscale 接口: $tailscale_iface"
> ```

### 第二步：配置 mihomo

需要修改三个方面的配置：

#### 1. DNS：强制通过 Tailscale 接口查询

使用 `#interface` 语法绑定 DNS 出站接口：

```yaml
dns:
  nameserver-policy:
    "+.ts.net":
      - "100.100.100.100#utun4"
```

`100.100.100.100#utun4` 告诉 mihomo：向 `100.100.100.100` 发 DNS 查询时，强制走 `utun4` 接口，不要自动检测。

> 不需要给 `tailscale.com` 配置 MagicDNS——它是普通互联网域名，用系统默认 DNS 解析即可。

> **踩坑提醒**：不要用 `%utun4`，`%` 会被解析为 URL 编码导致报错。正确语法是 `#`。

#### 2. 代理：创建绑定接口的 direct 代理

```yaml
proxies:
  - name: Tailscale
    type: direct
    interface-name: utun4
```

这定义了一个名为 `Tailscale` 的代理，本质是直连，但强制所有流量通过 `utun4` 接口发出。

#### 3. 规则：Tailscale 流量使用绑定接口的代理

```yaml
rules:
  # Tailscale 域名和 IP 走绑定 utun4 的 direct 代理
  - DOMAIN-SUFFIX,tail7f8eb.ts.net,Tailscale
  - IP-CIDR,100.64.0.0/10,Tailscale
  - IP-CIDR,fd7a:115c:a1e0::/48,Tailscale
  # Tailscale 进程本身保持 DIRECT（它自己管理路由）
  - PROCESS-NAME,tailscale,DIRECT
  - PROCESS-NAME,tailscaled,DIRECT
```

> **为什么不用 `DOMAIN-SUFFIX,ts.net`？** `ts.net` 会匹配所有 Tailscale 用户的域名。更精确的做法是只匹配你自己的 tailnet 域名（如 `tail7f8eb.ts.net`），在 Tailscale 管理后台的 DNS 页面可以查到。

> **为什么不加 `DOMAIN-SUFFIX,tailscale.com`？** `tailscale.com` 是普通互联网网站（文档、博客、管理后台），强制走 `utun4` 但没有配置出口节点会导致网站打不开。`tailscaled` 进程的控制面流量已经被 `PROCESS-NAME,tailscaled,DIRECT` 处理了，不需要域名规则兜底。

**关键**：域名和 IP 规则使用 `Tailscale`（绑定 utun4 的 direct 代理），而非 `DIRECT`。`DIRECT` 会触发 `auto-detect-interface`，又会错误地走 `en0`。

#### 4. TUN：排除 Tailscale 接口

```yaml
tun:
  exclude-interface:
    - utun4
```

防止 Tailscale 自身的流量被 TUN 拦截。

### 完整配置示例

以下是 Clash Party 覆写文件的完整示例：

```yaml
+proxies:
  - name: Tailscale
    type: direct
    interface-name: utun4

+rules:
  - DOMAIN-SUFFIX,tail7f8eb.ts.net,Tailscale
  - IP-CIDR,100.64.0.0/10,Tailscale
  - IP-CIDR,fd7a:115c:a1e0::/48,Tailscale
  - PROCESS-NAME,tailscale,DIRECT
  - PROCESS-NAME,tailscaled,DIRECT

dns:
  nameserver-policy:
    <+.ts.net>:
      - "100.100.100.100#utun4"

tun:
  exclude-interface:
    - utun4
```

> 注：`+rules:`、`+proxies:` 和 `<key>:` 是 Clash Party 的覆写语法。如果你使用其他客户端或直接编辑 mihomo 配置文件，请将这些内容合并到对应字段中。

### 另一个坑：`route-exclude-address` 不生效

你可能会想在 TUN 配置中添加 `route-exclude-address` 来排除 Tailscale 网段：

```yaml
tun:
  route-exclude-address:
    - 100.64.0.0/10
    - fd7a:115c:a1e0::/48
```

**但在 Clash Party 中这个配置大概率不生效。** Clash Party 的内核设置（`mihomo.yaml`）中 `route-exclude-address: []` 会在合并时覆盖覆写文件的值。即使直接编辑 `mihomo.yaml`，Clash Party 重启时也可能从内部状态恢复为空数组。

而且即使 `route-exclude-address` 生效，它只影响系统路由表，**不影响 mihomo 自身的 `auto-detect-interface` 行为**，所以并不能解决根本问题。真正的解决方案是上面的 `interface-name` + `#interface` 方案。推荐搭配 `tun.exclude-interface` 和 IP 规则来实现等效效果。

## 补充：配合 Peer Relay 使用

如果你有自建服务器（比如 VPS），可以配置 [Tailscale Peer Relay](https://tailscale.com/kb/1478/peer-relay)。Peer Relay 和本文的 TUN 共存方案是互补的：

- **TUN 共存方案**解决的是本地 Clash 和 Tailscale 流量路由冲突
- **Peer Relay** 解决的是节点之间的连接质量问题——当两个节点无法直连（NAT 打洞失败）时，流量会走 Tailscale 官方的 DERP 中继服务器，延迟较高。配置 Peer Relay 后，流量会优先走你自己的中继服务器，比 DERP 快得多

两者可以同时启用，互不冲突。

## 排查命令速查

```bash
# 查看 Tailscale 使用的接口
ifconfig | grep -E "^utun|inet 100\."

# 测试 Tailscale DNS 是否可达（系统级）
nslookup studio.tail7f8eb.ts.net 100.100.100.100

# 测试 mihomo 内部 DNS 解析（通过 API）
curl --noproxy '*' --unix-socket /tmp/mihomo-party-*.sock \
  "http://localhost/dns/query?name=studio.tail7f8eb.ts.net&type=A"

# 查看 mihomo 实时日志（含接口检测信息）
curl --noproxy '*' --unix-socket /tmp/mihomo-party-*.sock \
  "http://localhost/logs?level=debug" -N

# 查看系统路由表
netstat -rn | grep -E "utun|100\."

# 查看系统 DNS 配置
scutil --dns | head -30
```

## 总结

| 层面 | 问题 | 解决 |
| -------- | -------------------------------------------- | --------------------------------------------- |
| DNS 解析 | mihomo 向 `100.100.100.100` 查询时走了 `en0` | `nameserver-policy` 使用 `#utun4` 绑定接口 |
| TCP 连接 | mihomo 向 Tailscale IP 连接时走了 `en0` | `type: direct` + `interface-name: utun4` 代理 |
| TUN 拦截 | Tailscale 自身流量被 TUN 捕获 | `exclude-interface: utun4` |

一句话总结：**mihomo TUN 的防回环机制会绕过系统路由表，导致 Tailscale 的虚拟网卡流量被错误地发往物理网卡。解决方案是在 DNS 和代理两个层面都显式指定 `utun4` 接口。**


---

> 作者: [Chris](https://www.gameol.site)  
> URL: https://www.gameol.site/posts/20260211-clash-tun-tailscale-coexist/  

