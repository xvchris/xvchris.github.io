# 量化交易策略实践：从回测到实盘


# 量化交易策略实践：从回测到实盘



## 一、策略开发思路

### 1.1 策略选择

经过几个月的学习和实践，我终于决定开发自己的量化交易策略了。

说实话，一开始很迷茫，不知道从哪开始。看了很多论文和教程，最后还是决定从最简单的技术分析开始。

主要考虑因素：

- **市场适应性**：币圈波动太大，策略必须能适应
- **执行效率**：Rust性能好，适合高频交易
- **风险控制**：必须要有完善的风险管理，不能再像之前那样亏钱
- **可扩展性**：以后要支持多个币种和策略

### 1.2 策略框架

```rust
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StrategyConfig {
    pub name: String,
    pub symbols: Vec<String>,
    pub parameters: HashMap<String, f64>,
    pub risk_limits: RiskLimits,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RiskLimits {
    pub max_position_size: f64,
    pub max_drawdown: f64,
    pub stop_loss: f64,
    pub take_profit: f64,
}

#[derive(Debug, Clone)]
pub struct TradingSignal {
    pub symbol: String,
    pub action: SignalAction,
    pub price: f64,
    pub timestamp: u64,
    pub confidence: f64,
}

#[derive(Debug, Clone)]
pub enum SignalAction {
    Buy,
    Sell,
    Hold,
}
```

---

## 二、技术指标实现

### 2.1 移动平均线策略

```rust
use std::collections::VecDeque;

pub struct MovingAverageStrategy {
    short_window: usize,
    long_window: usize,
    short_ma: VecDeque<f64>,
    long_ma: VecDeque<f64>,
    config: StrategyConfig,
}

impl MovingAverageStrategy {
    pub fn new(config: StrategyConfig) -> Self {
        let short_window = *config.parameters.get("short_window").unwrap_or(&20.0) as usize;
        let long_window = *config.parameters.get("long_window").unwrap_or(&50.0) as usize;
        
        Self {
            short_window,
            long_window,
            short_ma: VecDeque::with_capacity(short_window),
            long_ma: VecDeque::with_capacity(long_window),
            config,
        }
    }
    
    pub fn update(&mut self, price: f64) -> Option<TradingSignal> {
        // 更新移动平均线
        self.short_ma.push_back(price);
        self.long_ma.push_back(price);
        
        if self.short_ma.len() > self.short_window {
            self.short_ma.pop_front();
        }
        if self.long_ma.len() > self.long_window {
            self.long_ma.pop_front();
        }
        
        // 计算移动平均线
        let short_avg = self.short_ma.iter().sum::<f64>() / self.short_ma.len() as f64;
        let long_avg = self.long_ma.iter().sum::<f64>() / self.long_ma.len() as f64;
        
        // 生成交易信号
        if self.short_ma.len() >= self.short_window && self.long_ma.len() >= self.long_window {
            let signal = self.generate_signal(price, short_avg, long_avg);
            return signal;
        }
        
        None
    }
    
    fn generate_signal(&self, price: f64, short_avg: f64, long_avg: f64) -> Option<TradingSignal> {
        let action = if short_avg > long_avg {
            SignalAction::Buy
        } else if short_avg < long_avg {
            SignalAction::Sell
        } else {
            SignalAction::Hold
        };
        
        let confidence = (short_avg - long_avg).abs() / price;
        
        Some(TradingSignal {
            symbol: self.config.symbols[0].clone(),
            action,
            price,
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs(),
            confidence,
        })
    }
}
```

### 2.2 RSI策略

```rust
pub struct RSIStrategy {
    period: usize,
    prices: VecDeque<f64>,
    gains: VecDeque<f64>,
    losses: VecDeque<f64>,
    config: StrategyConfig,
}

impl RSIStrategy {
    pub fn new(config: StrategyConfig) -> Self {
        let period = *config.parameters.get("rsi_period").unwrap_or(&14.0) as usize;
        
        Self {
            period,
            prices: VecDeque::with_capacity(period + 1),
            gains: VecDeque::with_capacity(period),
            losses: VecDeque::with_capacity(period),
            config,
        }
    }
    
    pub fn update(&mut self, price: f64) -> Option<TradingSignal> {
        self.prices.push_back(price);
        
        if self.prices.len() > self.period + 1 {
            self.prices.pop_front();
        }
        
        if self.prices.len() >= 2 {
            let change = self.prices[self.prices.len() - 1] - self.prices[self.prices.len() - 2];
            
            if change > 0.0 {
                self.gains.push_back(change);
                self.losses.push_back(0.0);
            } else {
                self.gains.push_back(0.0);
                self.losses.push_back(-change);
            }
            
            if self.gains.len() > self.period {
                self.gains.pop_front();
                self.losses.pop_front();
            }
        }
        
        if self.gains.len() >= self.period {
            let rsi = self.calculate_rsi();
            return self.generate_signal(price, rsi);
        }
        
        None
    }
    
    fn calculate_rsi(&self) -> f64 {
        let avg_gain = self.gains.iter().sum::<f64>() / self.period as f64;
        let avg_loss = self.losses.iter().sum::<f64>() / self.period as f64;
        
        if avg_loss == 0.0 {
            return 100.0;
        }
        
        let rs = avg_gain / avg_loss;
        100.0 - (100.0 / (1.0 + rs))
    }
    
    fn generate_signal(&self, price: f64, rsi: f64) -> Option<TradingSignal> {
        let action = if rsi < 30.0 {
            SignalAction::Buy
        } else if rsi > 70.0 {
            SignalAction::Sell
        } else {
            SignalAction::Hold
        };
        
        let confidence = if rsi < 30.0 || rsi > 70.0 {
            (rsi - 50.0).abs() / 50.0
        } else {
            0.0
        };
        
        Some(TradingSignal {
            symbol: self.config.symbols[0].clone(),
            action,
            price,
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs(),
            confidence,
        })
    }
}
```

---

## 三、策略回测系统

### 3.1 回测引擎

```rust
use std::collections::HashMap;

pub struct BacktestEngine {
    initial_capital: f64,
    current_capital: f64,
    positions: HashMap<String, f64>,
    trades: Vec<Trade>,
    equity_curve: Vec<f64>,
}

#[derive(Debug, Clone)]
pub struct Trade {
    pub symbol: String,
    pub action: SignalAction,
    pub price: f64,
    pub quantity: f64,
    pub timestamp: u64,
    pub pnl: f64,
}

impl BacktestEngine {
    pub fn new(initial_capital: f64) -> Self {
        Self {
            initial_capital,
            current_capital: initial_capital,
            positions: HashMap::new(),
            trades: Vec::new(),
            equity_curve: vec![initial_capital],
        }
    }
    
    pub fn execute_signal(&mut self, signal: &TradingSignal) -> Option<Trade> {
        let symbol = &signal.symbol;
        let current_position = self.positions.get(symbol).unwrap_or(&0.0);
        
        match signal.action {
            SignalAction::Buy => {
                if *current_position <= 0.0 {
                    let quantity = self.calculate_position_size(signal.price);
                    if quantity > 0.0 {
                        let cost = quantity * signal.price;
                        if cost <= self.current_capital {
                            self.current_capital -= cost;
                            *self.positions.entry(symbol.clone()).or_insert(0.0) += quantity;
                            
                            let trade = Trade {
                                symbol: symbol.clone(),
                                action: SignalAction::Buy,
                                price: signal.price,
                                quantity,
                                timestamp: signal.timestamp,
                                pnl: 0.0,
                            };
                            
                            self.trades.push(trade.clone());
                            self.update_equity_curve();
                            
                            return Some(trade);
                        }
                    }
                }
            }
            SignalAction::Sell => {
                if *current_position > 0.0 {
                    let quantity = *current_position;
                    let revenue = quantity * signal.price;
                    self.current_capital += revenue;
                    *self.positions.entry(symbol.clone()).or_insert(0.0) = 0.0;
                    
                    let trade = Trade {
                        symbol: symbol.clone(),
                        action: SignalAction::Sell,
                        price: signal.price,
                        quantity,
                        timestamp: signal.timestamp,
                        pnl: 0.0,
                    };
                    
                    self.trades.push(trade.clone());
                    self.update_equity_curve();
                    
                    return Some(trade);
                }
            }
            SignalAction::Hold => {}
        }
        
        None
    }
    
    fn calculate_position_size(&self, price: f64) -> f64 {
        // 简单的仓位计算，可以根据风险参数调整
        let risk_per_trade = 0.02; // 2%风险
        (self.current_capital * risk_per_trade) / price
    }
    
    fn update_equity_curve(&mut self) {
        let total_value = self.current_capital;
        for (symbol, position) in &self.positions {
            // 这里需要获取当前价格，简化处理
            let current_price = 0.0; // 实际应该从数据源获取
            total_value += position * current_price;
        }
        self.equity_curve.push(total_value);
    }
    
    pub fn get_performance_metrics(&self) -> PerformanceMetrics {
        let total_return = (self.equity_curve.last().unwrap() - self.initial_capital) 
                          / self.initial_capital;
        
        let returns: Vec<f64> = self.equity_curve.windows(2)
            .map(|w| (w[1] - w[0]) / w[0])
            .collect();
        
        let volatility = self.calculate_volatility(&returns);
        let sharpe_ratio = if volatility > 0.0 {
            returns.iter().sum::<f64>() / returns.len() as f64 / volatility
        } else {
            0.0
        };
        
        let max_drawdown = self.calculate_max_drawdown();
        
        PerformanceMetrics {
            total_return,
            volatility,
            sharpe_ratio,
            max_drawdown,
            total_trades: self.trades.len(),
        }
    }
    
    fn calculate_volatility(&self, returns: &[f64]) -> f64 {
        if returns.is_empty() {
            return 0.0;
        }
        
        let mean = returns.iter().sum::<f64>() / returns.len() as f64;
        let variance = returns.iter()
            .map(|r| (r - mean).powi(2))
            .sum::<f64>() / returns.len() as f64;
        
        variance.sqrt()
    }
    
    fn calculate_max_drawdown(&self) -> f64 {
        let mut max_drawdown = 0.0;
        let mut peak = self.equity_curve[0];
        
        for &value in &self.equity_curve {
            if value > peak {
                peak = value;
            }
            let drawdown = (peak - value) / peak;
            if drawdown > max_drawdown {
                max_drawdown = drawdown;
            }
        }
        
        max_drawdown
    }
}

#[derive(Debug)]
pub struct PerformanceMetrics {
    pub total_return: f64,
    pub volatility: f64,
    pub sharpe_ratio: f64,
    pub max_drawdown: f64,
    pub total_trades: usize,
}
```

### 3.2 回测运行

```rust
pub async fn run_backtest(
    strategy: &mut Box<dyn TradingStrategy>,
    data: &[PriceData],
    initial_capital: f64,
) -> BacktestEngine {
    let mut engine = BacktestEngine::new(initial_capital);
    
    for price_data in data {
        if let Some(signal) = strategy.update(price_data.price) {
            if let Some(trade) = engine.execute_signal(&signal) {
                println!("执行交易: {:?}", trade);
            }
        }
    }
    
    engine
}

// 使用示例
async fn backtest_example() {
    let config = StrategyConfig {
        name: "MA_Strategy".to_string(),
        symbols: vec!["BTC".to_string()],
        parameters: {
            let mut params = HashMap::new();
            params.insert("short_window".to_string(), 20.0);
            params.insert("long_window".to_string(), 50.0);
            params
        },
        risk_limits: RiskLimits {
            max_position_size: 0.1,
            max_drawdown: 0.2,
            stop_loss: 0.05,
            take_profit: 0.1,
        },
    };
    
    let mut strategy = Box::new(MovingAverageStrategy::new(config));
    
    // 加载历史数据
    let data = load_historical_data("BTC").await;
    
    // 运行回测
    let engine = run_backtest(&mut strategy, &data, 10000.0).await;
    
    // 输出结果
    let metrics = engine.get_performance_metrics();
    println!("回测结果: {:?}", metrics);
}
```

---

## 四、风险管理

### 4.1 风险控制模块

```rust
pub struct RiskManager {
    config: RiskLimits,
    current_positions: HashMap<String, f64>,
    position_costs: HashMap<String, f64>,
    daily_pnl: f64,
    max_drawdown: f64,
    peak_equity: f64,
}

impl RiskManager {
    pub fn new(config: RiskLimits) -> Self {
        Self {
            config,
            current_positions: HashMap::new(),
            position_costs: HashMap::new(),
            daily_pnl: 0.0,
            max_drawdown: 0.0,
            peak_equity: 0.0,
        }
    }
    
    pub fn check_risk_limits(&self, signal: &TradingSignal, current_equity: f64) -> bool {
        // 检查最大回撤
        if current_equity > self.peak_equity {
            self.peak_equity = current_equity;
        }
        
        let current_drawdown = (self.peak_equity - current_equity) / self.peak_equity;
        if current_drawdown > self.config.max_drawdown {
            return false;
        }
        
        // 检查仓位大小
        let current_position = self.current_positions.get(&signal.symbol).unwrap_or(&0.0);
        let position_value = current_position * signal.price;
        let equity_ratio = position_value / current_equity;
        
        if equity_ratio > self.config.max_position_size {
            return false;
        }
        
        true
    }
    
    pub fn calculate_position_size(&self, signal: &TradingSignal, current_equity: f64) -> f64 {
        let base_size = current_equity * self.config.max_position_size / signal.price;
        
        // 根据信号置信度调整仓位
        let adjusted_size = base_size * signal.confidence;
        
        // 应用止损限制
        let stop_loss_size = if signal.confidence > 0.5 {
            current_equity * self.config.stop_loss / signal.price
        } else {
            0.0
        };
        
        adjusted_size.min(stop_loss_size)
    }
    
    pub fn update_position(&mut self, symbol: &str, quantity: f64, price: f64) {
        let current_position = self.current_positions.get(symbol).unwrap_or(&0.0);
        let new_position = current_position + quantity;
        
        if new_position == 0.0 {
            self.current_positions.remove(symbol);
            self.position_costs.remove(symbol);
        } else {
            self.current_positions.insert(symbol.to_string(), new_position);
            
            let current_cost = self.position_costs.get(symbol).unwrap_or(&0.0);
            let new_cost = current_cost + (quantity * price);
            self.position_costs.insert(symbol.to_string(), new_cost);
        }
    }
    
    pub fn check_stop_loss(&self, symbol: &str, current_price: f64) -> bool {
        if let (Some(position), Some(cost)) = (
            self.current_positions.get(symbol),
            self.position_costs.get(symbol)
        ) {
            if *position > 0.0 {
                let avg_cost = cost / position;
                let loss_ratio = (avg_cost - current_price) / avg_cost;
                
                return loss_ratio > self.config.stop_loss;
            }
        }
        false
    }
    
    pub fn check_take_profit(&self, symbol: &str, current_price: f64) -> bool {
        if let (Some(position), Some(cost)) = (
            self.current_positions.get(symbol),
            self.position_costs.get(symbol)
        ) {
            if *position > 0.0 {
                let avg_cost = cost / position;
                let profit_ratio = (current_price - avg_cost) / avg_cost;
                
                return profit_ratio > self.config.take_profit;
            }
        }
        false
    }
}
```

---

## 五、实盘部署

### 5.1 交易所API集成

```rust
use reqwest;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct ExchangeConfig {
    pub name: String,
    pub api_key: String,
    pub secret_key: String,
    pub base_url: String,
}

pub struct ExchangeClient {
    config: ExchangeConfig,
    client: reqwest::Client,
}

impl ExchangeClient {
    pub fn new(config: ExchangeConfig) -> Self {
        Self {
            config,
            client: reqwest::Client::new(),
        }
    }
    
    pub async fn get_price(&self, symbol: &str) -> Result<f64, Box<dyn std::error::Error>> {
        let url = format!("{}/api/v3/ticker/price?symbol={}", self.config.base_url, symbol);
        let response = self.client.get(&url).send().await?;
        let data: serde_json::Value = response.json().await?;
        
        let price = data["price"].as_str()
            .ok_or("Price not found")?
            .parse::<f64>()?;
        
        Ok(price)
    }
    
    pub async fn place_order(&self, order: &Order) -> Result<String, Box<dyn std::error::Error>> {
        // 实现下单逻辑
        // 这里需要根据具体交易所API实现
        Ok("order_id".to_string())
    }
    
    pub async fn get_balance(&self) -> Result<f64, Box<dyn std::error::Error>> {
        // 实现余额查询
        Ok(1000.0)
    }
}

#[derive(Debug)]
pub struct Order {
    pub symbol: String,
    pub side: OrderSide,
    pub quantity: f64,
    pub price: Option<f64>,
    pub order_type: OrderType,
}

#[derive(Debug)]
pub enum OrderSide {
    Buy,
    Sell,
}

#[derive(Debug)]
pub enum OrderType {
    Market,
    Limit,
}
```

### 5.2 实盘交易系统

```rust
pub struct LiveTradingSystem {
    strategy: Box<dyn TradingStrategy>,
    risk_manager: RiskManager,
    exchange: ExchangeClient,
    is_running: bool,
}

impl LiveTradingSystem {
    pub fn new(
        strategy: Box<dyn TradingStrategy>,
        risk_manager: RiskManager,
        exchange: ExchangeClient,
    ) -> Self {
        Self {
            strategy,
            risk_manager,
            exchange,
            is_running: false,
        }
    }
    
    pub async fn start(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        self.is_running = true;
        
        while self.is_running {
            // 获取当前价格
            let symbol = &self.strategy.get_config().symbols[0];
            let price = self.exchange.get_price(symbol).await?;
            
            // 更新策略
            if let Some(signal) = self.strategy.update(price) {
                // 检查风险限制
                let balance = self.exchange.get_balance().await?;
                if self.risk_manager.check_risk_limits(&signal, balance) {
                    // 计算仓位大小
                    let quantity = self.risk_manager.calculate_position_size(&signal, balance);
                    
                    if quantity > 0.0 {
                        // 执行交易
                        let order = Order {
                            symbol: signal.symbol.clone(),
                            side: match signal.action {
                                SignalAction::Buy => OrderSide::Buy,
                                SignalAction::Sell => OrderSide::Sell,
                                SignalAction::Hold => continue,
                            },
                            quantity,
                            price: None, // 市价单
                            order_type: OrderType::Market,
                        };
                        
                        match self.exchange.place_order(&order).await {
                            Ok(order_id) => {
                                println!("订单执行成功: {}", order_id);
                                
                                // 更新风险管理器
                                self.risk_manager.update_position(
                                    &signal.symbol,
                                    quantity,
                                    price,
                                );
                            }
                            Err(e) => {
                                eprintln!("订单执行失败: {}", e);
                            }
                        }
                    }
                }
            }
            
            // 检查止损止盈
            for symbol in &self.strategy.get_config().symbols {
                if self.risk_manager.check_stop_loss(symbol, price) {
                    println!("触发止损: {}", symbol);
                    // 执行止损订单
                }
                
                if self.risk_manager.check_take_profit(symbol, price) {
                    println!("触发止盈: {}", symbol);
                    // 执行止盈订单
                }
            }
            
            // 等待一段时间
            tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
        }
        
        Ok(())
    }
    
    pub fn stop(&mut self) {
        self.is_running = false;
    }
}
```

---

## 六、经验总结

### 6.1 开发过程中的挑战

开发过程中遇到了很多问题：

**数据质量**：历史数据质量很差，经常有缺失和错误，影响回测结果。

**过拟合**：在历史数据上表现很好的策略，实盘中完全不行，亏得很惨。

**市场变化**：币圈变化太快，今天有效的策略明天可能就失效了。

**技术实现**：异步编程、错误处理等技术细节很复杂，经常出bug。

### 6.2 成功经验

经过这次实践，总结了一些经验：

1. **模块化设计**：把策略、风险管理、交易执行分开，便于维护
2. **充分测试**：实盘前一定要充分测试，不能急于求成
3. **风险控制**：风险管理比收益更重要，必须严格控制
4. **持续监控**：实盘交易要持续监控，及时调整

### 6.3 改进方向

接下来想改进的地方：

1. **多策略组合**：开发多个策略，分散风险
2. **机器学习**：试试用机器学习优化策略参数
3. **高频交易**：探索更高频率的交易策略
4. **跨市场套利**：在不同交易所间找套利机会

---

## 总结

量化交易确实很复杂，需要技术、金融、心理等多方面的能力。

通过这次实践，我对量化交易有了更深的理解，也发现了自己的不足。特别是风险控制方面，还需要加强。

接下来继续优化策略，希望能提高系统的稳定性和盈利能力。

---

*本文记录了量化交易策略从开发到实盘部署的完整过程，包括技术指标实现、回测系统、风险管理和实盘交易等核心内容。*


---

> 作者: [Chris]([author link])  
> URL: https://www.gameol.site/posts/20220815-trading-strategy-practice/  

