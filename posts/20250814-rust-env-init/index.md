# Rust开发环境初始化

# 开发环境配置指南（Zsh + Rust）



## 一、Zsh 环境配置

### 1. 安装 Zsh

```bash
sudo apt update
sudo apt install zsh -y
```

### 2. 设置 Zsh 为默认 shell

```bash
chsh -s $(which zsh)
```

> 注：执行后注销或重启终端即可生效。

### 3. 安装 Oh My Zsh

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

> Oh My Zsh 帮助管理主题和插件，安装后会自动切换到 Zsh。

### 4. 常用插件

#### 4.1 zsh-autosuggestions

自动命令补全：

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

编辑 `~/.zshrc`：

```bash
plugins=(... zsh-autosuggestions)
```

#### 4.2 zsh-syntax-highlighting

命令高亮：

```bash
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

在 `~/.zshrc` 末尾添加：

```bash
plugins=(... zsh-syntax-highlighting)
source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

#### 4.3 alias-finder

自动生成命令别名：

```bash
plugins=(... alias-finder)
```

使用示例：

```bash
alias-finder git status
# 输出：alias gs='git status'
```

#### 4.4 z

快速跳转目录：

```bash
plugins=(... z)
```

使用示例：

```bash
z myapp  # 跳转到常用目录 /home/user/projects/myapp
```

### 5. 常用设置

* 修改主题：

```bash
vim ~/.zshrc
# 修改 ZSH_THEME="robbyrussell" 为 ZSH_THEME="agnoster" 或其他
source ~/.zshrc
```

* 重新加载配置：

```bash
source ~/.zshrc
```

---

## 二、Rust 开发环境

### 1. 安装 C 编译器和开发依赖

Rust 需要 C 编译器来编译一些依赖包，首先安装必要的开发工具：

```bash
sudo apt update
sudo apt install build-essential libssl-dev pkg-config -y
```

**说明：**
- `build-essential`：包含 gcc、g++、make 等编译工具
- `libssl-dev`：OpenSSL 开发库，用于网络加密和 HTTPS 连接
- `pkg-config`：帮助编译器找到库文件的工具

### 2. 安装 Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
. "$HOME/.cargo/env"
```

### 3. 验证安装

```bash
rustc --version
cargo --version
```

### 4. 配置 Cargo 镜像

编辑 `~/.cargo/config.toml`：

```toml
[source.crates-io]
replace-with = 'ustc'

[source.ustc]
registry = "git://mirrors.ustc.edu.cn/crates.io-index"

[net]
git-fetch-with-cli = true
```

### 5. 可选：切换 Rust 版本

```bash
rustup default nightly
```

---

✅ 完成以上步骤后，你将拥有完整、现代化的 Zsh + Rust 开发环境，并可通过插件和配置提升开发效率。


---

> 作者: [Chris]([author link])  
> URL: https://www.gameol.site/posts/20250814-rust-env-init/  

