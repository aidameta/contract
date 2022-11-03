// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "https://github.com/0xcert/ethereum-erc721/src/contracts/ownership/ownable.sol";

interface ICrystalCoin {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // 注册可以提款的合约地址
    function registerContractAddress(address contractAddress) external;

    // 提款
    function transferCrystalCoin(address to, uint256 amount) external returns (bool);

    // 赎回
    function regainCrystalCoin(address from, uint256 amount) external returns (bool);

    struct lendData {
        address add;
        uint val;
        bool isValue;
    }

    // 获取所有账户提款总额
    function getLendData() external view returns (lendData[] memory lends);
}

contract CoinTransfer is Ownable {
    constructor() {
        address crystalCoinAddress = 0x1E7180Ae7345Fb8BB70593557F31cDca4Bf2fC44;
        _crystalCoin = ICrystalCoin(crystalCoinAddress);
        _rate = 1000000000000000000;
    }

    ICrystalCoin private _crystalCoin;
    uint private _rate;

    mapping(address => uint) _testCoin;

    /*
    * 这里的汇率是一个测试货币转换为10^(-18)个水晶币的数值
    * 汇率可以设置成一个自动调整的函数
    */
    function setExchangeRate(uint rate) public {
        _rate = rate;
    }

    function getExchangeRate() public view returns(uint) {
        return _rate;
    }

    function mintTestCoin(address to, uint amount) public onlyOwner returns (uint) {
        _testCoin[to] += amount;
        return _testCoin[to];
    }

    function getTestCoinBalance(address to) public view returns (uint) {
        return _testCoin[to];
    }

    /*
    * 用户使用测试货币兑换水晶币
    * 对于每个地址有一个兑换间隔
    */
    function exchangeCrystalCoin(address to, uint amount) public {
        require (_testCoin[to] >= amount, "money not enought" );
        _crystalCoin.transferCrystalCoin(to, amount * _rate);
        _testCoin[to] -= amount;
    }

    /*
    * 用户使用水晶币购买测试代币，crystalCoin单位为10^(-18)水晶币
    */
    function exchangeTestCoin(address to, uint crystalCoin) public {
        uint userCrystalCoinCount = _crystalCoin.balanceOf(to);
        require (userCrystalCoinCount >= crystalCoin, "money not enought");
        uint buyCoinCount = crystalCoin / _rate;
        require (buyCoinCount > 0, "money not enought");
        _crystalCoin.regainCrystalCoin(to, crystalCoin);

        _testCoin[to] += buyCoinCount;
    }
}