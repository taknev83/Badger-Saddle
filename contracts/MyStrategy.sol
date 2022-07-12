// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import "@openzeppelin-contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin-contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin-contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin-contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import {BaseStrategy} from "@badger-finance/BaseStrategy.sol";
import {ISwap} from "../interfaces/Saddle/ISwap.sol";
import {IGaugeDeposit} from "../interfaces/Saddle/IGaugeDeposit.sol";
import {ISDLMinter} from "../interfaces/Saddle/ISDLMinter.sol";
import {IRouter} from "../interfaces/sushi/IRouter.sol";

contract MyStrategy is BaseStrategy {
    // address public want; // Inherited from BaseStrategy
    // address public lpComponent; // Token that represents ownership in a pool, not always used
    // address public reward; // Token we farm

    // address constant BADGER = 0x3472A5A71965499acd81997a54BBA8D852C6E53d;

    address constant WRENSBTC_POOL = 0xdf3309771d2BF82cb2B6C56F9f5365C8bD97c4f2;
    address constant WRENSBTC_LPTOKEN = 0xF32E91464ca18fc156aB97a697D6f8ae66Cd21a3;
    address constant WRENSBTC_GAUGE_DEPOSIT = 0x17Bde8EBf1E9FDA85b9Bd1a104266b394E9Db33e;
    address constant SDL_MINTER = 0x358fE82370a1B9aDaE2E3ad69D6cF9e503c96018;
    address constant REWARD = 0xf1Dc500FdE233A4055e25e5BbF516372BC4F6871; //SDL Token
    // address constant ROUTER = 0xd9e1ce17f2641f24ae83637ab66a2cca9c378b9f;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    ISwap public constant IWRENSBTC_POOL = ISwap(0xdf3309771d2BF82cb2B6C56F9f5365C8bD97c4f2);
    IGaugeDeposit public constant IWRENSBTC_GAUGE_DEPOSIT = IGaugeDeposit(0x17Bde8EBf1E9FDA85b9Bd1a104266b394E9Db33e);
    ISDLMinter public constant ISDL_MINTER = ISDLMinter(0x358fE82370a1B9aDaE2E3ad69D6cF9e503c96018);
    IRouter public constant ROUTER = IRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    /// @dev Initialize the Strategy with security settings as well as tokens
    /// @notice Proxies will set any non constant variable you declare as default value
    /// @dev add any extra changeable variable at end of initializer as shown
    function initialize(address _vault, address[1] memory _wantConfig) public initializer {
        __BaseStrategy_init(_vault);
        /// @dev Add config here
        want = _wantConfig[0];

        // If you need to set new values that are not constants, set them like so
        // stakingContract = 0x79ba8b76F61Db3e7D994f7E384ba8f7870A043b7;

        // If you need to do one-off approvals do them here like so
        IERC20Upgradeable(want).safeApprove(address(IWRENSBTC_POOL), type(uint256).max);
        IERC20Upgradeable(want).safeApprove(address(IWRENSBTC_GAUGE_DEPOSIT), type(uint256).max);
        IERC20Upgradeable(WRENSBTC_LPTOKEN).safeApprove(want, type(uint256).max);
        IERC20Upgradeable(WRENSBTC_LPTOKEN).safeApprove(address(IWRENSBTC_GAUGE_DEPOSIT), type(uint256).max);
        IERC20Upgradeable(WRENSBTC_LPTOKEN).safeApprove(address(IWRENSBTC_POOL), type(uint256).max);
        IERC20Upgradeable(WRENSBTC_GAUGE_DEPOSIT).safeApprove(address(IWRENSBTC_GAUGE_DEPOSIT), type(uint256).max);
        IERC20Upgradeable(WRENSBTC_GAUGE_DEPOSIT).safeApprove(address(IWRENSBTC_POOL), type(uint256).max);

        //Approve for reward swapping
        IERC20Upgradeable(REWARD).safeApprove(address(ROUTER), type(uint256).max);
        IERC20Upgradeable(want).safeApprove(address(ROUTER), type(uint256).max);
        IERC20Upgradeable(WETH).safeApprove(address(ROUTER), type(uint256).max);
    }

    /// @dev Return the name of the strategy
    function getName() external pure override returns (string memory) {
        return "Badger-Saddle-WBTC-LP";
    }

    /// @dev Return a list of protected tokens
    /// @notice It's very important all tokens that are meant to be in the strategy to be marked as protected
    /// @notice this provides security guarantees to the depositors they can't be sweeped away
    function getProtectedTokens() public view virtual override returns (address[] memory) {
        address[] memory protectedTokens = new address[](4);
        protectedTokens[0] = want;
        protectedTokens[1] = WRENSBTC_LPTOKEN;
        protectedTokens[2] = WRENSBTC_GAUGE_DEPOSIT;
        protectedTokens[3] = REWARD;
        return protectedTokens;
    }

    /// @dev Deposit `_amount` of want, investing it to earn yield
    function _deposit(uint256 _amount) internal override {
        // Add code here to invest `_amount` of want to earn yield
        // adding liquidity in WBTC.
        uint256[] memory _amounts = new uint256[](3);
        _amounts[0] = _amount;
        _amounts[1] = 0;
        _amounts[2] = 0;
        IWRENSBTC_POOL.addLiquidity(_amounts, 0, block.timestamp);
        uint256 LP_Token_Bal = IERC20Upgradeable(WRENSBTC_LPTOKEN).balanceOf(address(this));
        require(LP_Token_Bal > 0, "No LP Token after addLiquidity");
        // staking the LP token
        IWRENSBTC_GAUGE_DEPOSIT.deposit(LP_Token_Bal, address(this), true);
        uint256 LP_Token_Stk_Bal = IERC20Upgradeable(WRENSBTC_GAUGE_DEPOSIT).balanceOf(address(this));
        require(LP_Token_Stk_Bal > 0, "No STK LP Token after deposit");
    }

    /// @dev Withdraw all funds, this is used for migrations, most of the time for emergency reasons
    function _withdrawAll() internal override {
        // Add code here to unlock all available funds
        uint256 LP_Token_Stk_Bal = IERC20Upgradeable(WRENSBTC_GAUGE_DEPOSIT).balanceOf(address(this));
        // require(LP_Token_Stk_Bal > 0, "No LP Token at withdraw All");
        IWRENSBTC_GAUGE_DEPOSIT.withdraw(LP_Token_Stk_Bal);
        uint256 LP_Token_Stk_Bal_Aft = IWRENSBTC_GAUGE_DEPOSIT.balanceOf(address(this));
        // require(LP_Token_Stk_Bal_Aft == 0, "STK LP Token balance non-zero after withdraw");
        uint256 LP_Token_Bal = IERC20Upgradeable(WRENSBTC_LPTOKEN).balanceOf(address(this));
        IWRENSBTC_POOL.removeLiquidityOneToken(LP_Token_Stk_Bal, 0, 0, block.timestamp); // to fix minOut (front running risk)
        uint256 LP_Token_Bal_Aft = IERC20Upgradeable(WRENSBTC_LPTOKEN).balanceOf(address(this));
        // require(LP_Token_Bal_Aft == 0, "LP Token balance non-zero after withdrawAll");
    }

    // function _calculateTokenAmount(uint256[3] calldata amounts, bool deposit) internal returns (uint256) {
    //     IWRENSBTC_POOL.calculateTokenAmount(amounts, deposit);
    // }

    /// @dev Withdraw `_amount` of want, so that it can be sent to the vault / depositor
    /// @notice just unlock the funds and return the amount you could unlock
    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        // Add code here to unlock / withdraw `_amount` of tokens to the withdrawer
        // If there's a loss, make sure to have the withdrawer pay the loss to avoid exploits
        // Socializing loss is always a bad idea
        if (_amount > balanceOfPool()) {
            _amount = balanceOfPool();
        }
        uint256 balBefore = balanceOfWant();
        uint256[] memory _amounts = new uint256[](3);
        _amounts[0] = _amount;
        _amounts[1] = 0;
        _amounts[2] = 0;
        uint256 withdrawTokenAmount = IWRENSBTC_POOL.calculateTokenAmount(_amounts, false);
        IWRENSBTC_GAUGE_DEPOSIT.withdraw(withdrawTokenAmount);
        uint256 LP_Token_Bal = IERC20Upgradeable(WRENSBTC_LPTOKEN).balanceOf(address(this));
        IWRENSBTC_POOL.removeLiquidityOneToken(withdrawTokenAmount, 0, 0, block.timestamp); // to fix minOut (front running risk)
        uint256 balAfter = balanceOfWant();
        return balAfter.sub(balBefore);
    }

    /// @dev Does this function require `tend` to be called?
    function _isTendable() internal pure override returns (bool) {
        return true; // Change to true if the strategy should be tended
    }

    function _harvest() internal override returns (TokenAmount[] memory harvested) {
        // No-op as we don't do anything with funds
        // use autoCompoundRatio here to convert rewards to want ...
        uint256 beforeWant = IERC20Upgradeable(want).balanceOf(address(this));
        ISDL_MINTER.mint(WRENSBTC_GAUGE_DEPOSIT);
        IWRENSBTC_GAUGE_DEPOSIT.claim_rewards(address(this));
        uint256 allRewards = IERC20Upgradeable(REWARD).balanceOf(address(this));
        // require(allRewards > 0, "No SDL Rewards");

        // Sell for more want
        harvested = new TokenAmount[](1);
        harvested[0] = TokenAmount(REWARD, 0);
        // harvested[1] = TokenAmount(want, 0);

        if (allRewards > 0) {
            harvested[0] = TokenAmount(REWARD, allRewards);

            address[] memory path = new address[](3);
            path[0] = REWARD;
            path[1] = WETH;
            path[2] = want;

            // IRouter(ROUTER).swapExactTokensForTokens(allRewards, 0, path, address(this), block.timestamp);
        } else {
            harvested[0] = TokenAmount(REWARD, 0);
        }
        _withdrawAll();
        uint256 wantBalance = IERC20Upgradeable(want).balanceOf(address(this)); // Cache to save gas on worst case
        _deposit(wantBalance);

        uint256 wantHarvested = IERC20Upgradeable(want).balanceOf(address(this)).sub(beforeWant);

        // Report profit for the want increase (NOTE: We are not getting perf fee on AAVE APY with this code)
        // _reportToVault(wantHarvested);

        // Use this if your strategy doesn't sell the extra tokens
        // This will take fees and send the token to the badgerTree
        _processExtraToken(REWARD, allRewards);

        return harvested;
    }

    // Example tend is a no-op which returns the values, could also just revert
    function _tend() internal override returns (TokenAmount[] memory tended) {
        uint256 balanceToTend = balanceOfWant();
        tended = new TokenAmount[](1);
        if (balanceToTend > 0) {
            _deposit(balanceToTend);
            tended[0] = TokenAmount(want, balanceToTend);
        } else {
            tended[0] = TokenAmount(want, 0);
        }
        return tended;
    }

    /// @dev Return the balance (in want) that the strategy has invested somewhere
    function balanceOfPool() public view override returns (uint256) {
        // Change this to return the amount of want invested in another protocol
        uint256 LP_Token_Stk_Bal = IERC20Upgradeable(WRENSBTC_GAUGE_DEPOSIT).balanceOf(address(this));
        // require(LP_Token_Stk_Bal > 0, "No STK LP in balanceOfPool");
        // uint256 balance = IWRENSBTC_POOL.calculateRemoveLiquidityOneToken(LP_Token_Stk_Bal, 0);
        // require(balance > 0, "0 Balance");
        // return balance;

        if (LP_Token_Stk_Bal > 0) {
            uint256 balance = IWRENSBTC_POOL.calculateRemoveLiquidityOneToken(LP_Token_Stk_Bal, 0);
            return balance;
        } else {
            return 0;
        }
    }

    /// @dev Return the balance of rewards that the strategy has accrued
    /// @notice Used for offChain APY and Harvest Health monitoring
    function balanceOfRewards() external view override returns (TokenAmount[] memory rewards) {
        uint256 claimableReward = IWRENSBTC_GAUGE_DEPOSIT.claimable_reward(address(this), REWARD);
        rewards = new TokenAmount[](1);
        rewards[0] = TokenAmount(REWARD, claimableReward);
        return rewards;
    }
}
