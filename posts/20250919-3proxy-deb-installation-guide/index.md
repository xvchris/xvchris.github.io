# 3proxy .Deb包安装教程：Socks5 + HTTP + 用户名密码认证


# 3proxy .deb包安装教程：Socks5 + HTTP + 用户名密码认证

## 前言

3proxy是一个轻量级的代理服务器，支持SOCKS5和HTTP代理协议。相比其他代理软件，3proxy配置简单，资源占用少，非常适合在VPS上部署。

本文将详细介绍如何使用.deb包安装3proxy，并配置SOCKS5和HTTP代理，同时启用用户名密码认证。

## 一、下载和安装3proxy

### 1.1 下载.deb包

```bash
wget https://github.com/3proxy/3proxy/releases/download/0.9.5/3proxy-0.9.5.x86_64.deb -O 3proxy.deb
```

### 1.2 安装3proxy

```bash
sudo dpkg -i 3proxy.deb
sudo apt-get install -f -y  # 修复依赖
```

安装完成后，3proxy会自动生成systemd服务文件：`/lib/systemd/system/3proxy.service`

## 二、停止默认服务并清理

### 2.1 停止systemd服务

```bash
sudo systemctl stop 3proxy.service
sudo systemctl disable 3proxy.service
sudo pkill -f 3proxy
```

### 2.2 确认端口已释放

```bash
sudo ss -tulnp | grep 3proxy
```

如果输出为空，说明没有残留进程，端口已释放。

## 三、配置SOCKS5 + HTTP代理

### 3.1 创建配置目录

```bash
sudo mkdir -p /etc/3proxy/conf
sudo nano /etc/3proxy/conf/3proxy.cfg
```

### 3.2 最小配置示例

```bash
daemon

# 用户认证
auth strong
users test:CL:123456
allow test

# SOCKS5 代理端口
socks -p1081

# HTTP 代理端口
proxy -p8080
```

**配置说明：**
- `daemon`：以守护进程模式运行
- `auth strong`：启用强认证
- `users test:CL:123456`：创建用户test，密码123456
- `allow test`：允许用户test访问
- `socks -p1081`：SOCKS5代理监听1081端口
- `proxy -p8080`：HTTP代理监听8080端口

⚠️ **注意**：.deb安装的3proxy默认日志可能报错，如果不需要日志，可以直接删除log配置。

## 四、手动启动测试

### 4.1 启动3proxy

```bash
sudo /usr/local/3proxy/3proxy /etc/3proxy/conf/3proxy.cfg
```

### 4.2 检查端口监听

```bash
sudo ss -tulnp | grep 3proxy
```

应该看到1081（SOCKS5）和8080（HTTP）端口在监听。

## 五、测试代理功能

### 5.1 Linux/macOS测试

**SOCKS5代理测试：**
```bash
curl -x socks5://test:123456@<服务器IP>:1081 http://httpbin.org/ip
```

**HTTP代理测试：**
```bash
curl -x http://test:123456@<服务器IP>:8080 http://httpbin.org/ip
```

如果返回服务器的公网IP，说明代理配置成功。

**注意事项：**
- macOS的curl如果`socks5h://`报错，使用`socks5://`即可
- 将`<服务器IP>`替换为实际的服务器IP地址

### 5.2 Windows测试

**使用curl for Windows：**
```cmd
curl -x socks5://test:123456@<服务器IP>:1081 http://httpbin.org/ip
curl -x http://test:123456@<服务器IP>:8080 http://httpbin.org/ip
```

## 六、配置systemd自启动

### 6.1 创建自定义systemd服务

```bash
sudo nano /etc/systemd/system/3proxy.service
```

### 6.2 服务文件内容

```ini
[Unit]
Description=3proxy tiny proxy server
After=network.target

[Service]
ExecStart=/usr/local/3proxy/3proxy /etc/3proxy/conf/3proxy.cfg
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### 6.3 启用并启动服务

```bash
sudo systemctl daemon-reload
sudo systemctl enable 3proxy.service
sudo systemctl start 3proxy.service
sudo systemctl status 3proxy.service
```

## 七、防火墙配置

### 7.1 本地防火墙放行

```bash
sudo ufw allow 1081/tcp
sudo ufw allow 8080/tcp
```

### 7.2 VPS提供商安全组配置

**重要提醒**：除了本地防火墙，还需要在VPS提供商的控制面板中配置安全组，放行相应端口：

- **阿里云ECS**：在安全组规则中添加1081和8080端口的入方向规则
- **腾讯云CVM**：在安全组中添加1081和8080端口的入站规则
- **AWS EC2**：在Security Groups中添加1081和8080端口的Inbound规则
- **DigitalOcean**：在Firewalls中添加1081和8080端口的Inbound规则

## 八、高级配置

### 8.1 多用户配置

```bash
daemon

# 多用户认证
auth strong
users user1:CL:password1
users user2:CL:password2
users user3:CL:password3

# 允许所有用户
allow user1
allow user2
allow user3

# 代理端口
socks -p1081
proxy -p8080
```

### 8.2 限制访问IP

```bash
daemon

# 用户认证
auth strong
users test:CL:123456

# 只允许特定IP访问
allow test 192.168.1.0/24
allow test 10.0.0.0/8

# 代理端口
socks -p1081
proxy -p8080
```

### 8.3 启用日志

```bash
daemon

# 日志配置
log /var/log/3proxy.log D
rotate 30

# 用户认证
auth strong
users test:CL:123456
allow test

# 代理端口
socks -p1081
proxy -p8080
```

## 九、常见问题排查

### 9.1 端口被占用

```bash
# 查看端口占用
sudo ss -tulnp | grep :1081
sudo ss -tulnp | grep :8080

# 杀死占用进程
sudo kill -9 <PID>
```

### 9.2 服务启动失败

```bash
# 查看服务状态
sudo systemctl status 3proxy.service

# 查看详细日志
sudo journalctl -u 3proxy.service -f
```

### 9.3 配置文件语法错误

```bash
# 测试配置文件语法
sudo /usr/local/3proxy/3proxy -c /etc/3proxy/conf/3proxy.cfg
```

## 十、安全建议

### 10.1 密码安全

- 使用强密码，包含大小写字母、数字和特殊字符
- 定期更换密码
- 避免使用常见密码

### 10.2 网络安全

- 限制访问IP范围
- 定期检查访问日志
- 考虑使用VPN + 代理的组合方案

### 10.3 系统安全

- 定期更新系统和软件包
- 监控系统资源使用情况
- 设置适当的文件权限

## 结语

通过本文的详细步骤，您已经成功部署了一个功能完整的3proxy代理服务器。这个配置支持SOCKS5和HTTP两种代理协议，并启用了用户名密码认证，可以满足大部分代理需求。

记住，代理服务器只是网络工具，请遵守当地法律法规，合理使用。同时，定期维护和更新配置，确保服务的安全性和稳定性。

---

*配置完成后，您就可以在客户端使用这个代理服务器了。如果遇到问题，可以参考常见问题排查部分，或者查看3proxy的官方文档。*


---

> 作者: [Chris](https://www.gameol.site)  
> URL: https://www.gameol.site/posts/20250919-3proxy-deb-installation-guide/  

