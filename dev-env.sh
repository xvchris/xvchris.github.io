#!/usr/bin/env bash

# ============================================
# Zsh + Rust 开发环境管理脚本
# ============================================
# 功能：安装、更新、验证开发环境
# 适用：Ubuntu/Debian/macOS
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}▶${NC} $1"
}

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/redhat-release ]]; then
        echo "redhat"
    else
        echo "unknown"
    fi
}

OS_TYPE=$(detect_os)

# ============================================
# 功能 1: 安装开发环境
# ============================================
install_env() {
    log_info "=========================================="
    log_info "开始安装开发环境"
    log_info "操作系统: $OS_TYPE"
    log_info "=========================================="
    echo ""

    # 检查是否为 root 用户
    if [ "$EUID" -eq 0 ]; then 
        log_error "请不要使用 root 用户运行此脚本"
        exit 1
    fi

    # 安装基础工具
    log_step "[1/7] 安装基础工具..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        if ! command -v brew &> /dev/null; then
            log_info "正在安装 Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install zsh git curl wget
        xcode-select --install 2>/dev/null || true
    elif [[ "$OS_TYPE" == "debian" ]]; then
        sudo apt update
        sudo apt install -y zsh git curl wget
    else
        log_error "不支持的操作系统"
        exit 1
    fi
    log_success "基础工具安装完成"
    echo ""

    # 安装 Oh My Zsh
    log_step "[2/7] 安装 Oh My Zsh..."
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_warning "Oh My Zsh 已安装，跳过"
    else
        RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        log_success "Oh My Zsh 安装完成"
    fi
    echo ""

    # 安装 Zsh 插件
    log_step "[3/7] 安装 Zsh 插件..."
    ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
    
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
    fi
    
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
    fi
    log_success "Zsh 插件安装完成"
    echo ""

    # 配置 .zshrc
    log_step "[4/7] 配置 .zshrc..."
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "已备份原有 .zshrc"
    fi

    # 根据操作系统调整配置
    if [[ "$OS_TYPE" == "macos" ]]; then
        LS_ALIAS='alias ls="ls -G"
alias ll="ls -lhG"
alias la="ls -lAhG"'
    else
        LS_ALIAS='alias ls="ls --color=auto"
alias ll="ls -lh"
alias la="ls -lAh"'
    fi

cat > "$HOME/.zshrc" << ZSHRC_EOF
# ============================================
# Oh My Zsh 基础配置
# ============================================
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# ============================================
# 插件配置
# ============================================
plugins=(
    git
    z
    zsh-autosuggestions
    zsh-syntax-highlighting
    sudo
    extract
    colored-man-pages
    command-not-found
    history-substring-search
)

source \$ZSH/oh-my-zsh.sh

# ============================================
# 环境变量配置
# ============================================
export EDITOR='vim'
export VISUAL='vim'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 历史命令配置
export HISTSIZE=10000
export SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# ============================================
# Rust 开发环境
# ============================================
if [ -f "\$HOME/.cargo/env" ]; then
    source "\$HOME/.cargo/env"
fi
export PATH="\$HOME/.cargo/bin:\$PATH"
export RUSTFLAGS="-C target-cpu=native"

# ============================================
# 自定义别名
# ============================================
alias cls='clear'
alias c='clear'
alias h='history'
alias q='exit'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

$LS_ALIAS
alias l='ls -CF'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Git 快捷命令
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'

# Rust 开发
alias cb='cargo build'
alias cr='cargo run'
alias ct='cargo test'
alias cc='cargo check'
alias cclean='cargo clean'
alias cupdate='cargo update'
alias cfmt='cargo fmt'
alias clippy='cargo clippy'

# 系统信息
alias meminfo='free -m -l -t 2>/dev/null || top -l 1 -s 0 | grep PhysMem'
alias cpuinfo='lscpu 2>/dev/null || sysctl -n machdep.cpu.brand_string'
alias diskinfo='df -h'

# 网络工具
alias myip='curl -s ifconfig.me'
alias ping='ping -c 5'

# ============================================
# 自定义函数
# ============================================
mkcd() { mkdir -p "\$1" && cd "\$1"; }
ff() { find . -type f -name "*\$1*"; }
fd() { find . -type d -name "*\$1*"; }
newrust() { cargo new "\$1" && cd "\$1"; }

# ============================================
# 终端优化
# ============================================
stty -ixon 2>/dev/null || true

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "\$(dircolors -b ~/.dircolors)" || eval "\$(dircolors -b)"
fi

# ============================================
# 加载本地私有配置
# ============================================
if [ -f ~/.zshrc.local ]; then
    source ~/.zshrc.local
fi
ZSHRC_EOF

    log_success ".zshrc 配置完成"
    echo ""

    # 安装 Rust 依赖
    log_step "[5/7] 安装 Rust 依赖..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        brew install openssl pkg-config
    else
        sudo apt install -y build-essential libssl-dev pkg-config
    fi
    log_success "Rust 依赖安装完成"
    echo ""

    # 安装 Rust
    log_step "[6/7] 安装 Rust..."
    if command -v rustc &> /dev/null; then
        log_warning "Rust 已安装，跳过"
        rustc --version
    else
        log_info "使用国内镜像加速下载..."
        # 使用中科大镜像加速
        export RUSTUP_DIST_SERVER="https://mirrors.ustc.edu.cn/rust-static"
        export RUSTUP_UPDATE_ROOT="https://mirrors.ustc.edu.cn/rust-static/rustup"
        
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
        source "$HOME/.cargo/env"
        log_success "Rust 安装完成"
        rustc --version
        cargo --version
    fi
    echo ""

    # 配置 Cargo 镜像
    log_step "[7/7] 配置 Cargo 镜像..."
    mkdir -p "$HOME/.cargo"
    cat > "$HOME/.cargo/config.toml" << 'CARGO_EOF'
[source.crates-io]
replace-with = 'ustc'

[source.ustc]
registry = "git://mirrors.ustc.edu.cn/crates.io-index"

[net]
git-fetch-with-cli = true
CARGO_EOF
    log_success "Cargo 镜像配置完成"
    echo ""

    # 设置默认 shell
    if [ "$SHELL" != "$(which zsh)" ]; then
        log_info "设置 Zsh 为默认 shell..."
        chsh -s $(which zsh) 2>/dev/null && log_success "已设置" || log_warning "需要手动运行: chsh -s \$(which zsh)"
    fi

    echo ""
    log_success "=========================================="
    log_success "开发环境安装完成！"
    log_success "=========================================="
    echo ""
    log_warning "请执行以下命令之一来启用新配置："
    log_warning "  1. 重新打开终端"
    log_warning "  2. 执行: exec zsh"
    log_warning "  3. 执行: source ~/.zshrc"
    echo ""
}

# ============================================
# 功能 2: 安装 Rust 工具
# ============================================
install_tools() {
    log_info "=========================================="
    log_info "安装 Rust 常用工具"
    log_info "=========================================="
    echo ""

    if ! command -v cargo &> /dev/null; then
        log_error "Rust 未安装，请先运行: $0 install"
        exit 1
    fi

    log_step "安装基础组件..."
    rustup component add rustfmt clippy
    echo ""

    log_step "安装 Cargo 扩展工具..."
    echo "这可能需要一些时间，请耐心等待..."
    cargo install \
        cargo-edit \
        cargo-watch \
        cargo-audit \
        cargo-outdated \
        cargo-bloat \
        cargo-expand \
        bacon \
        sccache \
        tokei \
        hyperfine

    echo ""
    log_success "=========================================="
    log_success "所有工具安装完成！"
    log_success "=========================================="
    echo ""
    log_info "已安装的工具："
    log_info "  ✓ rustfmt, clippy      - 代码格式化和检查"
    log_info "  ✓ cargo-edit           - 管理依赖 (cargo add/rm)"
    log_info "  ✓ cargo-watch          - 自动重新编译"
    log_info "  ✓ cargo-audit          - 安全漏洞检查"
    log_info "  ✓ cargo-outdated       - 检查过期依赖"
    log_info "  ✓ cargo-bloat          - 分析二进制大小"
    log_info "  ✓ cargo-expand         - 宏展开"
    log_info "  ✓ bacon                - 后台编译检查"
    log_info "  ✓ sccache              - 编译缓存加速"
    log_info "  ✓ tokei                - 代码行数统计"
    log_info "  ✓ hyperfine            - 性能基准测试"
    echo ""
}

# ============================================
# 功能 3: 更新环境
# ============================================
update_env() {
    log_info "=========================================="
    log_info "更新开发环境"
    log_info "=========================================="
    echo ""

    log_step "[1/4] 更新 Rust 工具链..."
    if command -v rustup &> /dev/null; then
        rustup update
        log_success "Rust 更新完成"
    else
        log_warning "Rust 未安装"
    fi
    echo ""

    log_step "[2/4] 更新 Cargo 工具..."
    if command -v cargo-install-update &> /dev/null; then
        cargo install-update -a
        log_success "Cargo 工具更新完成"
    else
        log_warning "cargo-update 未安装，跳过"
        log_info "提示: 运行 'cargo install cargo-update' 安装"
    fi
    echo ""

    log_step "[3/4] 更新 Oh My Zsh..."
    if [ -d ~/.oh-my-zsh ]; then
        cd ~/.oh-my-zsh && git pull
        log_success "Oh My Zsh 更新完成"
    else
        log_warning "Oh My Zsh 未安装"
    fi
    echo ""

    log_step "[4/4] 更新 Zsh 插件..."
    if [ -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]; then
        cd ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions && git pull
        log_success "zsh-autosuggestions 更新完成"
    fi
    if [ -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]; then
        cd ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && git pull
        log_success "zsh-syntax-highlighting 更新完成"
    fi
    echo ""

    log_success "=========================================="
    log_success "所有更新完成！"
    log_success "=========================================="
    echo ""
}

# ============================================
# 功能 4: 验证环境
# ============================================
verify_env() {
    check_command() {
        if command -v $1 &> /dev/null; then
            echo -e "${GREEN}✓${NC} $1: $(command -v $1)"
            if [ ! -z "$2" ]; then
                echo "  版本: $($1 $2 2>&1 | head -n1)"
            fi
            return 0
        else
            echo -e "${RED}✗${NC} $1: 未安装"
            return 1
        fi
    }

    check_file() {
        if [ -f "$1" ]; then
            echo -e "${GREEN}✓${NC} $1"
            return 0
        else
            echo -e "${RED}✗${NC} $1"
            return 1
        fi
    }

    check_dir() {
        if [ -d "$1" ]; then
            echo -e "${GREEN}✓${NC} $1"
            return 0
        else
            echo -e "${RED}✗${NC} $1"
            return 1
        fi
    }

    echo ""
    log_info "=========================================="
    log_info "开发环境验证报告"
    log_info "=========================================="
    echo ""

    echo -e "${YELLOW}▶ Shell 环境${NC}"
    check_command zsh --version
    echo "  当前 Shell: $SHELL"
    check_dir ~/.oh-my-zsh
    echo ""

    echo -e "${YELLOW}▶ Rust 工具链${NC}"
    check_command rustc --version
    check_command cargo --version
    check_command rustup --version
    echo ""

    echo -e "${YELLOW}▶ Rust 组件${NC}"
    rustup component list --installed 2>/dev/null | grep -q rustfmt && echo -e "${GREEN}✓${NC} rustfmt" || echo -e "${RED}✗${NC} rustfmt"
    rustup component list --installed 2>/dev/null | grep -q clippy && echo -e "${GREEN}✓${NC} clippy" || echo -e "${RED}✗${NC} clippy"
    echo ""

    echo -e "${YELLOW}▶ Cargo 扩展工具${NC}"
    check_command cargo-watch --version 2>/dev/null
    check_command cargo-edit --version 2>/dev/null
    check_command bacon --version 2>/dev/null
    check_command sccache --version 2>/dev/null
    echo ""

    echo -e "${YELLOW}▶ 配置文件${NC}"
    check_file ~/.zshrc
    check_file ~/.cargo/config.toml
    check_dir ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    check_dir ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    echo ""

    echo -e "${YELLOW}▶ 性能测试${NC}"
    if command -v zsh &> /dev/null; then
        zsh_startup=$(command time -p zsh -i -c exit 2>&1 | grep real | awk '{print $2}' || echo "N/A")
        echo "  Zsh 启动时间: ${zsh_startup}s"
    fi
    echo ""

    log_info "=========================================="
    log_info "验证完成"
    log_info "=========================================="
    echo ""
}

# ============================================
# 显示帮助信息
# ============================================
show_help() {
    cat << EOF
${CYAN}Zsh + Rust 开发环境管理脚本${NC}

${YELLOW}用法:${NC}
    $0 <命令> [选项]

${YELLOW}命令:${NC}
    install     安装完整的开发环境 (Zsh + Oh My Zsh + Rust)
    tools       安装 Rust 常用开发工具
    update      更新所有已安装的工具和环境
    verify      验证环境配置和安装状态
    help        显示此帮助信息

${YELLOW}示例:${NC}
    # 新系统初始化
    $0 install

    # 安装 Rust 工具链
    $0 tools

    # 定期更新环境
    $0 update

    # 检查环境状态
    $0 verify

${YELLOW}推荐流程:${NC}
    1. $0 install    # 首次安装
    2. exec zsh         # 重新加载
    3. $0 tools      # 安装工具（可选）
    4. $0 verify     # 验证环境

${YELLOW}支持的系统:${NC}
    - Ubuntu 18.04+
    - Debian 10+
    - macOS 11.0+

EOF
}

# ============================================
# 交互式菜单
# ============================================
show_menu() {
    while true; do
        echo ""
        echo -e "${CYAN}=========================================="
        echo "  Zsh + Rust 开发环境管理"
        echo "==========================================${NC}"
        echo ""
        echo "  1) 安装开发环境 (首次使用)"
        echo "  2) 安装 Rust 工具"
        echo "  3) 更新环境"
        echo "  4) 验证环境"
        echo "  5) 显示帮助"
        echo "  0) 退出"
        echo ""
        read -p "请选择操作 [0-5]: " choice

        case $choice in
            1)
                install_env
                ;;
            2)
                install_tools
                ;;
            3)
                update_env
                ;;
            4)
                verify_env
                ;;
            5)
                show_help
                ;;
            0)
                echo ""
                log_info "退出程序"
                exit 0
                ;;
            *)
                log_error "无效的选择，请重新输入"
                ;;
        esac

        echo ""
        read -p "按 Enter 键继续..."
    done
}

# ============================================
# 主程序
# ============================================
main() {
    # 如果没有参数，显示交互式菜单
    if [ $# -eq 0 ]; then
        show_menu
        exit 0
    fi

    # 根据参数执行相应功能
    case "$1" in
        install)
            install_env
            ;;
        tools)
            install_tools
            ;;
        update)
            update_env
            ;;
        verify)
            verify_env
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 运行主程序
main "$@"

