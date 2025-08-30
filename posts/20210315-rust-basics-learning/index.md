# Rust语言入门：从零开始的学习笔记


# Rust语言入门：从零开始的学习笔记



## 一、为什么选择Rust

### 1.1 学习动机

说实话，选择Rust完全是个意外。

那天在GitHub上看到一个很酷的量化交易项目，作者用Rust写的，性能比Python快了10倍。我当时就想：这什么语言这么厉害？

查了一下，发现Rust确实很特别：
- **内存安全**：不会像C++那样动不动就段错误
- **性能优秀**：接近C/C++的速度，但没有那些坑
- **并发安全**：编译时就能发现线程问题
- **零成本抽象**：高级语法，低级性能

最重要的是，我想做量化交易，对性能要求很高。Python虽然好写，但速度确实是个问题。

### 1.2 学习目标

我的目标很简单：
- 能看懂Rust代码，理解基本概念
- 能写一些简单的程序
- 最终能用Rust写量化交易策略

不求精通，但求能用。

---

## 二、环境搭建

### 2.1 安装Rust

```bash
# 安装rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 配置环境变量
source ~/.cargo/env

# 验证安装
rustc --version
cargo --version
```

### 2.2 配置IDE

选择使用VS Code + rust-analyzer插件，配置如下：

```json
// settings.json
{
    "rust-analyzer.checkOnSave.command": "clippy",
    "rust-analyzer.cargo.loadOutDirsFromCheck": true,
    "rust-analyzer.procMacro.enable": true
}
```

---

## 三、基础语法学习

### 3.1 Hello World

```rust
fn main() {
    println!("Hello, Rust!");
}
```

### 3.2 变量和类型

```rust
fn main() {
    // 不可变变量
    let x = 5;
    println!("x = {}", x);
    
    // 可变变量
    let mut y = 10;
    y = 15;
    println!("y = {}", y);
    
    // 类型注解
    let z: i32 = 20;
    let f: f64 = 3.14;
    let b: bool = true;
    let c: char = 'A';
    
    // 字符串
    let s1 = "Hello"; // &str
    let s2 = String::from("World"); // String
    println!("{} {}", s1, s2);
}
```

### 3.3 函数定义

```rust
// 基本函数
fn add(a: i32, b: i32) -> i32 {
    a + b
}

// 带默认参数的函数（Rust不支持默认参数，但可以用Option）
fn greet(name: Option<&str>) {
    match name {
        Some(n) => println!("Hello, {}!", n),
        None => println!("Hello, World!"),
    }
}

// 闭包
fn main() {
    let add_one = |x| x + 1;
    println!("5 + 1 = {}", add_one(5));
    
    // 使用函数
    let result = add(3, 4);
    println!("3 + 4 = {}", result);
    
    greet(Some("Rust"));
    greet(None);
}
```

---

## 四、所有权系统

### 4.1 所有权概念

```rust
fn main() {
    // 栈上的数据
    let x = 5;
    let y = x; // 复制，x仍然可用
    println!("x = {}, y = {}", x, y);
    
    // 堆上的数据
    let s1 = String::from("hello");
    let s2 = s1; // 移动，s1不再可用
    // println!("s1 = {}", s1); // 编译错误
    println!("s2 = {}", s2);
    
    // 克隆
    let s3 = String::from("world");
    let s4 = s3.clone(); // 深拷贝
    println!("s3 = {}, s4 = {}", s3, s4);
}
```

### 4.2 引用和借用

```rust
fn main() {
    let s1 = String::from("hello");
    
    // 不可变引用
    let len = calculate_length(&s1);
    println!("'{}' 的长度是 {}", s1, len);
    
    // 可变引用
    let mut s2 = String::from("hello");
    change(&mut s2);
    println!("s2 = {}", s2);
}

fn calculate_length(s: &String) -> usize {
    s.len()
}

fn change(s: &mut String) {
    s.push_str(" world");
}
```

### 4.3 生命周期

```rust
// 生命周期注解
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() {
        x
    } else {
        y
    }
}

fn main() {
    let string1 = String::from("abcd");
    let string2 = "xyz";
    
    let result = longest(string1.as_str(), string2);
    println!("最长的字符串是 {}", result);
}
```

---

## 五、错误处理

### 5.1 Result类型

```rust
use std::fs::File;
use std::io::{self, Read};

fn read_username_from_file() -> Result<String, io::Error> {
    let mut f = File::open("hello.txt")?;
    let mut s = String::new();
    f.read_to_string(&mut s)?;
    Ok(s)
}

fn main() {
    match read_username_from_file() {
        Ok(username) => println!("用户名: {}", username),
        Err(e) => println!("错误: {}", e),
    }
}
```

### 5.2 Option类型

```rust
fn find_user(id: u32) -> Option<&'static str> {
    match id {
        1 => Some("Alice"),
        2 => Some("Bob"),
        _ => None,
    }
}

fn main() {
    let user = find_user(1);
    match user {
        Some(name) => println!("找到用户: {}", name),
        None => println!("用户不存在"),
    }
    
    // 使用if let简化
    if let Some(name) = find_user(2) {
        println!("找到用户: {}", name);
    }
}
```

---

## 六、学习心得

### 6.1 学习过程中的困难

说实话，Rust真的很难学。

**所有权概念**：刚开始完全懵逼，为什么不能同时借用可变和不可变？为什么String赋值后原来的就没了？这些概念在其他语言里根本不存在。

**生命周期**：这个更抽象，什么'a、'b的，看得我头大。到现在我也不是完全理解。

**错误处理**：Result和Option确实比异常处理更安全，但写起来真的很啰嗦。

### 6.2 学习建议

基于我的经验：

1. **不要急**：Rust需要时间，不要想着一周就能学会
2. **多写代码**：光看书没用，必须动手写
3. **从简单开始**：不要一开始就写复杂的项目
4. **看别人的代码**：GitHub上有很多好的Rust项目

### 6.3 下一步计划

现在基础差不多了，接下来想：
- 学学异步编程，听说很厉害
- 试试Web框架，看看能不能写个简单的API
- 最终目标：用Rust写量化交易策略

---

## 总结

Rust确实很难，但值得学。

虽然现在写代码还是很慢，经常被borrow checker卡住，但至少不用担心内存泄漏和段错误了。

对于量化交易这种对性能要求高的场景，Rust确实是个不错的选择。虽然学习成本高，但长期来看是值得的。

接下来继续加油吧！

---

*本文记录了Rust语言入门学习的过程，包括基础语法、所有权系统、错误处理等核心概念的学习笔记。*


---

> 作者: [Chris]([author link])  
> URL: https://www.gameol.site/posts/20210315-rust-basics-learning/  

