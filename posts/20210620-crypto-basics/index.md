# 加密货币基础知识：从比特币到DeFi


# 加密货币基础知识：从比特币到DeFi



## 一、为什么关注加密货币

### 1.1 市场背景

那年的币圈真的太疯狂了。

比特币从年初的3万刀涨到6万刀，以太坊从1000刀涨到4000刀。朋友圈里天天有人晒收益，各种"财富自由"的帖子刷屏。

说实话，一开始我是拒绝的。觉得这就是泡沫，迟早要崩。

但看着身边的朋友一个个赚得盆满钵满，我也开始心动了。

### 1.2 个人兴趣

后来深入了解后，发现加密货币确实很有意思：

- **技术创新**：区块链技术确实很酷，去中心化的概念很吸引人
- **投资机会**：虽然风险很大，但机会也很多
- **编程实践**：智能合约开发是个很好的编程练习
- **量化交易**：24/7交易，没有涨跌停，很适合量化策略

最重要的是，我想试试能不能用技术来赚钱。

---

## 二、比特币：数字黄金

### 2.1 比特币基础

比特币是第一个去中心化的数字货币，由中本聪在2008年提出。

**核心特点：**
- 去中心化：没有中央机构控制
- 有限供应：总量2100万个
- 不可篡改：基于密码学保证安全
- 全球流通：无国界限制

### 2.2 技术原理

```python
# 简化的比特币地址生成示例
import hashlib
import base58

def generate_bitcoin_address(public_key):
    """生成比特币地址"""
    # SHA256哈希
    sha256_hash = hashlib.sha256(public_key.encode()).hexdigest()
    
    # RIPEMD160哈希
    ripemd160_hash = hashlib.new('ripemd160', sha256_hash.encode()).hexdigest()
    
    # 添加版本号
    versioned_hash = "00" + ripemd160_hash
    
    # 双重SHA256校验
    checksum = hashlib.sha256(hashlib.sha256(versioned_hash.encode()).digest()).hexdigest()[:8]
    
    # 组合并Base58编码
    final_hash = versioned_hash + checksum
    address = base58.b58encode(bytes.fromhex(final_hash)).decode()
    
    return address

# 使用示例
public_key = "04a0434d9e47f3c86235477c7b1ae6ae5d3442d49b1943c2b752a68e2a47e247c7"
address = generate_bitcoin_address(public_key)
print(f"比特币地址: {address}")
```

### 2.3 挖矿原理

```python
import hashlib
import time

def mine_block(block_data, target_difficulty):
    """简单的挖矿模拟"""
    nonce = 0
    target = "0" * target_difficulty
    
    while True:
        # 组合区块数据
        block_string = f"{block_data}{nonce}"
        
        # 计算哈希
        block_hash = hashlib.sha256(block_string.encode()).hexdigest()
        
        # 检查是否满足难度要求
        if block_hash[:target_difficulty] == target:
            return nonce, block_hash
        
        nonce += 1

# 挖矿示例
block_data = "Hello, Bitcoin!"
difficulty = 4
start_time = time.time()

nonce, block_hash = mine_block(block_data, difficulty)
end_time = time.time()

print(f"找到有效nonce: {nonce}")
print(f"区块哈希: {block_hash}")
print(f"耗时: {end_time - start_time:.2f}秒")
```

---

## 三、以太坊：智能合约平台

### 3.1 以太坊基础

以太坊不仅是一个数字货币，更是一个去中心化的计算平台。

**核心特点：**
- 智能合约：可编程的区块链
- 图灵完备：支持复杂的计算逻辑
- 去中心化应用（DApp）：构建在以太坊上的应用

### 3.2 智能合约示例

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        
        emit Transfer(from, to, amount);
        return true;
    }
}
```

---

## 四、DeFi：去中心化金融

### 4.1 DeFi概念

DeFi（去中心化金融）是建立在区块链上的金融服务，无需传统金融机构中介。

**主要应用：**
- 去中心化交易所（DEX）
- 借贷平台
- 流动性挖矿
- 稳定币

### 4.2 流动性挖矿示例

```solidity
// 简化的流动性挖矿合约
contract LiquidityMining {
    IERC20 public rewardToken;
    IERC20 public lpToken;
    
    uint256 public rewardPerBlock;
    uint256 public lastUpdateBlock;
    uint256 public rewardPerTokenStored;
    
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public balanceOf;
    
    uint256 public totalSupply;
    
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    
    constructor(address _rewardToken, address _lpToken, uint256 _rewardPerBlock) {
        rewardToken = IERC20(_rewardToken);
        lpToken = IERC20(_lpToken);
        rewardPerBlock = _rewardPerBlock;
    }
    
    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");
        
        totalSupply += amount;
        balanceOf[msg.sender] += amount;
        
        updateReward(msg.sender);
        
        lpToken.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }
    
    function withdraw(uint256 amount) external {
        require(amount > 0, "Cannot withdraw 0");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        
        updateReward(msg.sender);
        
        lpToken.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }
    
    function getReward() external {
        updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }
    
    function updateReward(address account) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateBlock = block.number;
        
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }
    
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + 
               (((block.number - lastUpdateBlock) * rewardPerBlock * 1e18) / totalSupply);
    }
    
    function earned(address account) public view returns (uint256) {
        return (balanceOf[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18 + 
               rewards[account];
    }
}
```

---

## 五、技术分析基础

### 5.1 基本指标

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

def calculate_sma(prices, window):
    """计算简单移动平均线"""
    return prices.rolling(window=window).mean()

def calculate_ema(prices, window):
    """计算指数移动平均线"""
    return prices.ewm(span=window).mean()

def calculate_rsi(prices, window=14):
    """计算RSI指标"""
    delta = prices.diff()
    gain = (delta.where(delta > 0, 0)).rolling(window=window).mean()
    loss = (-delta.where(delta < 0, 0)).rolling(window=window).mean()
    
    rs = gain / loss
    rsi = 100 - (100 / (1 + rs))
    return rsi

def calculate_bollinger_bands(prices, window=20, std_dev=2):
    """计算布林带"""
    sma = prices.rolling(window=window).mean()
    std = prices.rolling(window=window).std()
    
    upper_band = sma + (std * std_dev)
    lower_band = sma - (std * std_dev)
    
    return upper_band, sma, lower_band

# 使用示例
def analyze_crypto_data(prices):
    """分析加密货币数据"""
    # 计算技术指标
    sma_20 = calculate_sma(prices, 20)
    sma_50 = calculate_sma(prices, 50)
    rsi = calculate_rsi(prices)
    bb_upper, bb_middle, bb_lower = calculate_bollinger_bands(prices)
    
    # 创建图表
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8))
    
    # 价格和移动平均线
    ax1.plot(prices.index, prices, label='Price', alpha=0.7)
    ax1.plot(prices.index, sma_20, label='SMA 20', alpha=0.7)
    ax1.plot(prices.index, sma_50, label='SMA 50', alpha=0.7)
    ax1.fill_between(prices.index, bb_upper, bb_lower, alpha=0.1, label='Bollinger Bands')
    ax1.set_title('Crypto Price Analysis')
    ax1.legend()
    ax1.grid(True)
    
    # RSI指标
    ax2.plot(prices.index, rsi, label='RSI', color='purple')
    ax2.axhline(y=70, color='r', linestyle='--', alpha=0.7)
    ax2.axhline(y=30, color='g', linestyle='--', alpha=0.7)
    ax2.set_title('RSI Indicator')
    ax2.legend()
    ax2.grid(True)
    
    plt.tight_layout()
    plt.show()
    
    return {
        'sma_20': sma_20,
        'sma_50': sma_50,
        'rsi': rsi,
        'bb_upper': bb_upper,
        'bb_lower': bb_lower
    }
```

### 5.2 交易信号

```python
def generate_signals(prices, sma_20, sma_50, rsi):
    """生成交易信号"""
    signals = pd.Series(0, index=prices.index)
    
    # 金叉买入信号
    signals[(sma_20 > sma_50) & (sma_20.shift(1) <= sma_50.shift(1))] = 1
    
    # 死叉卖出信号
    signals[(sma_20 < sma_50) & (sma_20.shift(1) >= sma_50.shift(1))] = -1
    
    # RSI超买超卖信号
    signals[rsi > 70] = -1  # 超买
    signals[rsi < 30] = 1   # 超卖
    
    return signals

def backtest_strategy(prices, signals):
    """回测策略"""
    position = 0
    cash = 10000  # 初始资金
    portfolio_value = []
    
    for i, (price, signal) in enumerate(zip(prices, signals)):
        if signal == 1 and position == 0:  # 买入
            position = cash / price
            cash = 0
        elif signal == -1 and position > 0:  # 卖出
            cash = position * price
            position = 0
        
        # 计算组合价值
        current_value = cash + position * price
        portfolio_value.append(current_value)
    
    return portfolio_value
```

---

## 六、学习心得

### 6.1 市场观察

经过这段时间的学习，我发现币圈真的很特别：

**高波动性**：一天涨跌20%很正常，心脏不好的真的不适合玩。

**24/7交易**：没有休息日，随时可以交易，但也意味着随时可能亏钱。

**技术创新**：新技术层出不穷，今天还是热点，明天可能就过时了。

### 6.2 投资策略

基于我的观察：

1. **不要梭哈**：再看好也不要all in，分散投资很重要
2. **长期思维**：短期波动太大，要有长期持有的心态
3. **技术分析**：虽然不能完全依赖，但比瞎买强

### 6.3 技术学习

接下来想学的东西：

1. **智能合约**：Solidity语言，想自己写个简单的合约
2. **量化交易**：用Rust写自动化交易策略
3. **区块链原理**：深入理解底层技术

---

## 总结

币圈确实很疯狂，但也很有趣。

虽然风险很大，但机会也很多。作为技术人，我觉得最重要的是理解背后的技术原理，而不是盲目跟风。

接下来继续学习，希望能在这个领域有所收获。

---

*本文记录了加密货币基础知识的学习过程，包括比特币、以太坊、DeFi等核心概念，以及技术分析的基础知识。*


---

> 作者: [Chris]([author link])  
> URL: https://www.gameol.site/posts/20210620-crypto-basics/  

