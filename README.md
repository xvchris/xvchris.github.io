# Static 资源说明

本目录存放博客的静态资源文件，这些文件会被 Hugo 直接复制到发布目录，可通过网站根路径直接访问。

## 📁 目录结构

```
static/
├── dev-env.sh          # 开发环境管理脚本
├── CNAME               # 自定义域名配置
├── favicons/           # 网站图标
└── README.md           # 本说明文件
```

## 📦 可下载资源

### dev-env.sh
**Zsh + Rust 开发环境一键管理脚本**

- **访问URL**: https://www.gameol.site/dev-env.sh
- **大小**: ~20KB
- **功能**: 
  - 安装 Zsh + Oh My Zsh + Rust 环境
  - 安装 20+ 个 Rust 开发工具
  - 更新和验证环境
  - 交互式菜单和命令行双模式
  - 支持 Ubuntu/Debian/macOS

## 🌐 访问方式

### 浏览器下载
直接访问：
- 下载页面: https://www.gameol.site/downloads/
- 直接下载: https://www.gameol.site/dev-env.sh

### 命令行下载
```bash
# 使用 wget
wget https://www.gameol.site/dev-env.sh

# 使用 curl
curl -O https://www.gameol.site/dev-env.sh

# 赋予执行权限
chmod +x dev-env.sh

# 运行
./dev-env.sh
```

## 📝 添加新的下载资源

1. 将文件放入 `static/` 目录
2. 文件将自动发布到网站根目录
3. 访问 URL: `https://www.gameol.site/文件名`
4. 更新 `content/downloads.md` 页面添加下载说明

## 🎨 下载按钮样式

在 Markdown 文件中使用以下代码创建下载按钮：

```html
<a href="/文件名" download="文件名" class="button">
  <i class="fa-solid fa-download"></i> 下载文件
</a>
```

按钮样式已在 `assets/css/_custom.scss` 中定义。

## ⚠️ 注意事项

1. **文件大小**: 避免放置过大的文件（>10MB）
2. **安全性**: 确保上传的脚本是安全的
3. **版本管理**: 建议为重要文件添加版本号
4. **文档同步**: 更新资源时记得同步更新文档

## 🔗 相关文件

- 下载页面: `content/downloads.md`
- 菜单配置: `config/_default/menus.toml`
- 按钮样式: `assets/css/_custom.scss`
- 使用文档: `content/posts/dev/20250814-rust-env-init.md`

---

最后更新：2025-10-29

