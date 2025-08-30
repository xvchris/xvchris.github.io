# Rust异步编程学习：从Future到async/Await


# Rust异步编程学习：从Future到async/await



## 一、为什么学习异步编程

### 1.1 学习动机

说实话，学异步编程完全是被逼的。

我的量化交易系统需要同时连接多个交易所API，处理实时数据流。用同步的方式写，代码慢得像蜗牛，而且经常卡死。

特别是处理WebSocket连接时，同步代码根本搞不定。要么是阻塞，要么是死锁。

所以只能硬着头皮学异步编程了。

### 1.2 异步编程的优势

学了一段时间后，发现异步编程确实很厉害：

- **高并发**：一个线程能处理几百个连接
- **低延迟**：没有线程切换的开销
- **资源效率**：内存占用少很多
- **可扩展性**：能处理大量并发连接

对于量化交易这种对性能要求很高的场景，异步编程几乎是必须的。

---

## 二、Future trait基础

### 2.1 Future概念

Future是Rust异步编程的核心概念，代表一个可能还没有完成的计算。

```rust
use std::future::Future;
use std::pin::Pin;
use std::task::{Context, Poll};

// 自定义Future
struct SimpleFuture {
    value: Option<i32>,
}

impl Future for SimpleFuture {
    type Output = i32;
    
    fn poll(mut self: Pin<&mut Self>, _cx: &mut Context<'_>) -> Poll<Self::Output> {
        match self.value {
            Some(value) => Poll::Ready(value),
            None => {
                // 模拟异步操作
                self.value = Some(42);
                Poll::Pending
            }
        }
    }
}

// 使用Future
async fn use_simple_future() {
    let future = SimpleFuture { value: None };
    let result = future.await;
    println!("Future结果: {}", result);
}
```

### 2.2 组合Future

```rust
use std::future::Future;
use std::pin::Pin;
use std::task::{Context, Poll};

// 组合多个Future
struct CombinedFuture<F1, F2> {
    future1: F1,
    future2: F2,
    state: State,
}

enum State {
    First,
    Second,
    Done,
}

impl<F1, F2> CombinedFuture<F1, F2>
where
    F1: Future<Output = i32>,
    F2: Future<Output = i32>,
{
    fn new(future1: F1, future2: F2) -> Self {
        Self {
            future1,
            future2,
            state: State::First,
        }
    }
}

impl<F1, F2> Future for CombinedFuture<F1, F2>
where
    F1: Future<Output = i32>,
    F2: Future<Output = i32>,
{
    type Output = (i32, i32);
    
    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        match self.state {
            State::First => {
                let result1 = match Pin::new(&mut self.future1).poll(cx) {
                    Poll::Ready(value) => value,
                    Poll::Pending => return Poll::Pending,
                };
                self.state = State::Second;
                cx.waker().wake_by_ref();
                Poll::Pending
            }
            State::Second => {
                let result2 = match Pin::new(&mut self.future2).poll(cx) {
                    Poll::Ready(value) => value,
                    Poll::Pending => return Poll::Pending,
                };
                self.state = State::Done;
                Poll::Ready((result1, result2))
            }
            State::Done => panic!("Future已经完成"),
        }
    }
}
```

---

## 三、async/await语法

### 3.1 基本语法

```rust
use tokio::time::{sleep, Duration};

// 基本异步函数
async fn fetch_data(id: u32) -> String {
    // 模拟网络请求延迟
    sleep(Duration::from_millis(100)).await;
    format!("数据 {}", id)
}

// 异步函数组合
async fn process_multiple_data() {
    let data1 = fetch_data(1).await;
    let data2 = fetch_data(2).await;
    let data3 = fetch_data(3).await;
    
    println!("处理结果: {}, {}, {}", data1, data2, data3);
}

// 并发执行
async fn process_concurrent_data() {
    let future1 = fetch_data(1);
    let future2 = fetch_data(2);
    let future3 = fetch_data(3);
    
    // 同时执行多个异步任务
    let (data1, data2, data3) = tokio::join!(future1, future2, future3);
    
    println!("并发结果: {}, {}, {}", data1, data2, data3);
}

// 选择第一个完成的任务
async fn race_futures() {
    let future1 = fetch_data(1);
    let future2 = fetch_data(2);
    
    let result = tokio::select! {
        data1 = future1 => format!("Future1完成: {}", data1),
        data2 = future2 => format!("Future2完成: {}", data2),
    };
    
    println!("竞速结果: {}", result);
}
```

### 3.2 错误处理

```rust
use std::io;

// 异步函数中的错误处理
async fn fetch_data_with_error(id: u32) -> Result<String, io::Error> {
    if id == 0 {
        return Err(io::Error::new(io::ErrorKind::InvalidInput, "无效ID"));
    }
    
    sleep(Duration::from_millis(100)).await;
    Ok(format!("数据 {}", id))
}

// 使用?操作符
async fn process_with_error_handling() -> Result<(), io::Error> {
    let data1 = fetch_data_with_error(1)?;
    let data2 = fetch_data_with_error(2)?;
    
    println!("处理结果: {}, {}", data1, data2);
    Ok(())
}

// 错误传播
async fn handle_errors() {
    match process_with_error_handling().await {
        Ok(()) => println!("处理成功"),
        Err(e) => println!("处理失败: {}", e),
    }
}
```

---

## 四、Tokio运行时

### 4.1 运行时配置

```rust
use tokio::runtime::{Runtime, Builder};

// 创建多线程运行时
fn create_multi_thread_runtime() -> Runtime {
    Builder::new_multi_thread()
        .worker_threads(4)
        .enable_all()
        .build()
        .unwrap()
}

// 创建单线程运行时
fn create_current_thread_runtime() -> Runtime {
    Builder::new_current_thread()
        .enable_all()
        .build()
        .unwrap()
}

// 运行时使用示例
async fn runtime_example() {
    let rt = create_multi_thread_runtime();
    
    // 在运行时中执行异步任务
    let result = rt.block_on(async {
        let data = fetch_data(1).await;
        format!("运行时结果: {}", data)
    });
    
    println!("{}", result);
}
```

### 4.2 通道通信

```rust
use tokio::sync::mpsc;

// 生产者-消费者模式
async fn producer_consumer_example() {
    let (tx, mut rx) = mpsc::channel(100);
    
    // 生产者任务
    let producer = tokio::spawn(async move {
        for i in 0..10 {
            let data = fetch_data(i).await;
            tx.send(data).await.unwrap();
        }
    });
    
    // 消费者任务
    let consumer = tokio::spawn(async move {
        while let Some(data) = rx.recv().await {
            println!("接收到数据: {}", data);
        }
    });
    
    // 等待任务完成
    let _ = tokio::join!(producer, consumer);
}

// 广播通道
use tokio::sync::broadcast;

async fn broadcast_example() {
    let (tx, _) = broadcast::channel(16);
    let mut rx1 = tx.subscribe();
    let mut rx2 = tx.subscribe();
    
    // 发送者
    let sender = tokio::spawn(async move {
        for i in 0..5 {
            tx.send(format!("消息 {}", i)).unwrap();
            sleep(Duration::from_millis(100)).await;
        }
    });
    
    // 接收者1
    let receiver1 = tokio::spawn(async move {
        while let Ok(msg) = rx1.recv().await {
            println!("接收者1: {}", msg);
        }
    });
    
    // 接收者2
    let receiver2 = tokio::spawn(async move {
        while let Ok(msg) = rx2.recv().await {
            println!("接收者2: {}", msg);
        }
    });
    
    let _ = tokio::join!(sender, receiver1, receiver2);
}
```

---

## 五、实际应用案例

### 5.1 量化交易数据获取

```rust
use reqwest;
use serde::{Deserialize, Serialize};
use tokio::time::interval;

#[derive(Debug, Serialize, Deserialize)]
struct PriceData {
    symbol: String,
    price: f64,
    timestamp: u64,
}

// 异步获取价格数据
async fn fetch_price_data(symbol: &str) -> Result<PriceData, reqwest::Error> {
    let url = format!("https://api.example.com/price/{}", symbol);
    let response = reqwest::get(&url).await?;
    let price_data: PriceData = response.json().await?;
    Ok(price_data)
}

// 实时价格监控
async fn price_monitor(symbols: Vec<String>) {
    let mut interval = interval(Duration::from_secs(1));
    
    loop {
        interval.tick().await;
        
        let mut futures = Vec::new();
        for symbol in &symbols {
            let future = fetch_price_data(symbol);
            futures.push(future);
        }
        
        // 并发获取所有价格
        let results = futures::future::join_all(futures).await;
        
        for result in results {
            match result {
                Ok(price_data) => {
                    println!("{}: ${:.2}", price_data.symbol, price_data.price);
                }
                Err(e) => {
                    eprintln!("获取价格失败: {}", e);
                }
            }
        }
    }
}

// 交易信号生成
async fn generate_trading_signals() {
    let symbols = vec!["BTC", "ETH", "ADA"];
    
    // 启动价格监控
    let monitor_handle = tokio::spawn(price_monitor(symbols));
    
    // 信号生成逻辑
    let signal_handle = tokio::spawn(async move {
        let mut interval = interval(Duration::from_secs(5));
        
        loop {
            interval.tick().await;
            
            // 这里实现交易信号生成逻辑
            println!("生成交易信号...");
        }
    });
    
    let _ = tokio::join!(monitor_handle, signal_handle);
}
```

### 5.2 WebSocket连接管理

```rust
use tokio_tungstenite::{connect_async, WebSocketStream};
use futures::{SinkExt, StreamExt};
use url::Url;

// WebSocket连接
async fn websocket_connection(url: &str) -> Result<(), Box<dyn std::error::Error>> {
    let url = url.parse::<Url>()?;
    let (ws_stream, _) = connect_async(url).await?;
    
    let (mut write, mut read) = ws_stream.split();
    
    // 发送消息
    let message = "Hello WebSocket";
    write.send(message.into()).await?;
    
    // 接收消息
    while let Some(msg) = read.next().await {
        match msg {
            Ok(msg) => {
                println!("收到消息: {}", msg);
            }
            Err(e) => {
                eprintln!("WebSocket错误: {}", e);
                break;
            }
        }
    }
    
    Ok(())
}

// 多个WebSocket连接管理
async fn manage_multiple_connections() {
    let urls = vec![
        "wss://stream1.example.com",
        "wss://stream2.example.com",
        "wss://stream3.example.com",
    ];
    
    let mut handles = Vec::new();
    
    for url in urls {
        let handle = tokio::spawn(async move {
            if let Err(e) = websocket_connection(url).await {
                eprintln!("连接失败 {}: {}", url, e);
            }
        });
        handles.push(handle);
    }
    
    // 等待所有连接完成
    for handle in handles {
        let _ = handle.await;
    }
}
```

---

## 六、学习心得

### 6.1 学习过程中的困难

异步编程真的很难学，比我想象的难多了：

**概念理解**：Future、Poll、Waker这些概念太抽象了，看了很多遍才勉强理解。

**生命周期**：异步代码中的生命周期管理比同步代码复杂很多，经常编译不过。

**错误处理**：异步错误传播和处理方式很特别，需要时间适应。

**调试困难**：异步代码调试真的很痛苦，经常不知道程序卡在哪里。

### 6.2 学习建议

基于我的经验：

1. **不要急**：异步编程需要时间，不要想着一周就能学会
2. **从简单开始**：先写简单的异步代码，再逐步复杂
3. **多写代码**：光看书没用，必须动手写
4. **理解原理**：不要只学语法，要理解底层原理

### 6.3 实际应用

现在我的量化交易系统已经用上了异步编程：

- **多交易所连接**：同时连接5个交易所，处理实时数据
- **WebSocket管理**：稳定处理大量WebSocket连接
- **高并发处理**：每秒处理几万条数据

---

## 总结

异步编程确实很难，但值得学。

虽然学习过程很痛苦，但掌握后能写出性能很好的程序。对于量化交易这种对性能要求很高的场景，异步编程几乎是必须的。

现在我的系统性能提升了很多，延迟从几十毫秒降到了几毫秒。

继续加油吧！

---

*本文记录了Rust异步编程的学习过程，包括Future trait、async/await语法、Tokio运行时等核心概念的学习笔记。*


---

> 作者: [Chris]([author link])  
> URL: https://www.gameol.site/posts/20220210-rust-async-learning/  

