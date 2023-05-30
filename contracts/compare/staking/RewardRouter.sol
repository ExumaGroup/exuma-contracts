// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";
import "../libraries/utils/Address.sol";

import "./interfaces/IRewardTracker.sol";
import "../tokens/interfaces/IMintable.sol";
import "../tokens/interfaces/IWETH.sol";
import "../core/interfaces/IGlpManager.sol";
import "../access/Governable.sol";

contract RewardRouter_Original is ReentrancyGuard_Original, Governable_Original {
    using SafeMath_Original for uint256;
    using SafeERC20_Original for IERC20_Original;
    using Address_Original for address payable;

    bool public isInitialized;

    address public weth;

    address public gmx;
    address public esGmx;
    address public bnGmx;

    address public glp; // GMX Liquidity Provider token

    address public stakedGmxTracker;
    address public bonusGmxTracker;
    address public feeGmxTracker;

    address public stakedGlpTracker;
    address public feeGlpTracker;

    address public glpManager;

    event StakeGmx(address account, uint256 amount);
    event UnstakeGmx(address account, uint256 amount);

    event StakeGlp(address account, uint256 amount);
    event UnstakeGlp(address account, uint256 amount);

    receive() external payable {
        require(msg.sender == weth, "Router: invalid sender");
    }

    function initialize(
        address _weth,
        address _gmx,
        address _esGmx,
        address _bnGmx,
        address _glp,
        address _stakedGmxTracker,
        address _bonusGmxTracker,
        address _feeGmxTracker,
        address _feeGlpTracker,
        address _stakedGlpTracker,
        address _glpManager
    ) external onlyGov {
        require(!isInitialized, "RewardRouter: already initialized");
        isInitialized = true;

        weth = _weth;

        gmx = _gmx;
        esGmx = _esGmx;
        bnGmx = _bnGmx;

        glp = _glp;

        stakedGmxTracker = _stakedGmxTracker;
        bonusGmxTracker = _bonusGmxTracker;
        feeGmxTracker = _feeGmxTracker;

        feeGlpTracker = _feeGlpTracker;
        stakedGlpTracker = _stakedGlpTracker;

        glpManager = _glpManager;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken_Original(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20_Original(_token).safeTransfer(_account, _amount);
    }

    function batchStakeGmxForAccount(address[] memory _accounts, uint256[] memory _amounts) external nonReentrant onlyGov {
        address _gmx = gmx;
        for (uint256 i = 0; i < _accounts.length; i++) {
            _stakeGmx(msg.sender, _accounts[i], _gmx, _amounts[i]);
        }
    }

    function stakeGmxForAccount(address _account, uint256 _amount) external nonReentrant onlyGov {
        _stakeGmx(msg.sender, _account, gmx, _amount);
    }

    function stakeGmx(uint256 _amount) external nonReentrant {
        _stakeGmx(msg.sender, msg.sender, gmx, _amount);
    }

    function stakeEsGmx(uint256 _amount) external nonReentrant {
        _stakeGmx(msg.sender, msg.sender, esGmx, _amount);
    }

    function unstakeGmx(uint256 _amount) external nonReentrant {
        _unstakeGmx(msg.sender, gmx, _amount);
    }

    function unstakeEsGmx(uint256 _amount) external nonReentrant {
        _unstakeGmx(msg.sender, esGmx, _amount);
    }

    function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external nonReentrant returns (uint256) {
        require(_amount > 0, "RewardRouter: invalid _amount");

        address account = msg.sender;
        uint256 glpAmount = IGlpManager_Original(glpManager).addLiquidityForAccount(account, account, _token, _amount, _minUsdg, _minGlp);
        IRewardTracker_Original(feeGlpTracker).stakeForAccount(account, account, glp, glpAmount);
        IRewardTracker_Original(stakedGlpTracker).stakeForAccount(account, account, feeGlpTracker, glpAmount);

        emit StakeGlp(account, glpAmount);

        return glpAmount;
    }

    function mintAndStakeGlpETH(uint256 _minUsdg, uint256 _minGlp) external payable nonReentrant returns (uint256) {
        require(msg.value > 0, "RewardRouter: invalid msg.value");

        IWETH_Original(weth).deposit{value: msg.value}();
        IERC20_Original(weth).approve(glpManager, msg.value);

        address account = msg.sender;
        uint256 glpAmount = IGlpManager_Original(glpManager).addLiquidityForAccount(address(this), account, weth, msg.value, _minUsdg, _minGlp);

        IRewardTracker_Original(feeGlpTracker).stakeForAccount(account, account, glp, glpAmount);
        IRewardTracker_Original(stakedGlpTracker).stakeForAccount(account, account, feeGlpTracker, glpAmount);

        emit StakeGlp(account, glpAmount);

        return glpAmount;
    }

    function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external nonReentrant returns (uint256) {
        require(_glpAmount > 0, "RewardRouter: invalid _glpAmount");

        address account = msg.sender;
        IRewardTracker_Original(stakedGlpTracker).unstakeForAccount(account, feeGlpTracker, _glpAmount, account);
        IRewardTracker_Original(feeGlpTracker).unstakeForAccount(account, glp, _glpAmount, account);
        uint256 amountOut = IGlpManager_Original(glpManager).removeLiquidityForAccount(account, _tokenOut, _glpAmount, _minOut, _receiver);

        emit UnstakeGlp(account, _glpAmount);

        return amountOut;
    }

    function unstakeAndRedeemGlpETH(uint256 _glpAmount, uint256 _minOut, address payable _receiver) external nonReentrant returns (uint256) {
        require(_glpAmount > 0, "RewardRouter: invalid _glpAmount");

        address account = msg.sender;
        IRewardTracker_Original(stakedGlpTracker).unstakeForAccount(account, feeGlpTracker, _glpAmount, account);
        IRewardTracker_Original(feeGlpTracker).unstakeForAccount(account, glp, _glpAmount, account);
        uint256 amountOut = IGlpManager_Original(glpManager).removeLiquidityForAccount(account, weth, _glpAmount, _minOut, address(this));

        IWETH_Original(weth).withdraw(amountOut);

        _receiver.sendValue(amountOut);

        emit UnstakeGlp(account, _glpAmount);

        return amountOut;
    }

    function claim() external nonReentrant {
        address account = msg.sender;

        IRewardTracker_Original(feeGmxTracker).claimForAccount(account, account);
        IRewardTracker_Original(feeGlpTracker).claimForAccount(account, account);

        IRewardTracker_Original(stakedGmxTracker).claimForAccount(account, account);
        IRewardTracker_Original(stakedGlpTracker).claimForAccount(account, account);
    }

    function claimEsGmx() external nonReentrant {
        address account = msg.sender;

        IRewardTracker_Original(stakedGmxTracker).claimForAccount(account, account);
        IRewardTracker_Original(stakedGlpTracker).claimForAccount(account, account);
    }

    function claimFees() external nonReentrant {
        address account = msg.sender;

        IRewardTracker_Original(feeGmxTracker).claimForAccount(account, account);
        IRewardTracker_Original(feeGlpTracker).claimForAccount(account, account);
    }

    function compound() external nonReentrant {
        _compound(msg.sender);
    }

    function compoundForAccount(address _account) external nonReentrant onlyGov {
        _compound(_account);
    }

    function batchCompoundForAccounts(address[] memory _accounts) external nonReentrant onlyGov {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _compound(_accounts[i]);
        }
    }

    function _compound(address _account) private {
        _compoundGmx(_account);
        _compoundGlp(_account);
    }

    function _compoundGmx(address _account) private {
        uint256 esGmxAmount = IRewardTracker_Original(stakedGmxTracker).claimForAccount(_account, _account);
        if (esGmxAmount > 0) {
            _stakeGmx(_account, _account, esGmx, esGmxAmount);
        }

        uint256 bnGmxAmount = IRewardTracker_Original(bonusGmxTracker).claimForAccount(_account, _account);
        if (bnGmxAmount > 0) {
            IRewardTracker_Original(feeGmxTracker).stakeForAccount(_account, _account, bnGmx, bnGmxAmount);
        }
    }

    function _compoundGlp(address _account) private {
        uint256 esGmxAmount = IRewardTracker_Original(stakedGlpTracker).claimForAccount(_account, _account);
        if (esGmxAmount > 0) {
            _stakeGmx(_account, _account, esGmx, esGmxAmount);
        }
    }

    function _stakeGmx(address _fundingAccount, address _account, address _token, uint256 _amount) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        IRewardTracker_Original(stakedGmxTracker).stakeForAccount(_fundingAccount, _account, _token, _amount);
        IRewardTracker_Original(bonusGmxTracker).stakeForAccount(_account, _account, stakedGmxTracker, _amount);
        IRewardTracker_Original(feeGmxTracker).stakeForAccount(_account, _account, bonusGmxTracker, _amount);

        emit StakeGmx(_account, _amount);
    }

    function _unstakeGmx(address _account, address _token, uint256 _amount) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        uint256 balance = IRewardTracker_Original(stakedGmxTracker).stakedAmounts(_account);

        IRewardTracker_Original(feeGmxTracker).unstakeForAccount(_account, bonusGmxTracker, _amount, _account);
        IRewardTracker_Original(bonusGmxTracker).unstakeForAccount(_account, stakedGmxTracker, _amount, _account);
        IRewardTracker_Original(stakedGmxTracker).unstakeForAccount(_account, _token, _amount, _account);

        uint256 bnGmxAmount = IRewardTracker_Original(bonusGmxTracker).claimForAccount(_account, _account);
        if (bnGmxAmount > 0) {
            IRewardTracker_Original(feeGmxTracker).stakeForAccount(_account, _account, bnGmx, bnGmxAmount);
        }

        uint256 stakedBnGmx = IRewardTracker_Original(feeGmxTracker).depositBalances(_account, bnGmx);
        if (stakedBnGmx > 0) {
            uint256 reductionAmount = stakedBnGmx.mul(_amount).div(balance);
            IRewardTracker_Original(feeGmxTracker).unstakeForAccount(_account, bnGmx, reductionAmount, _account);
            IMintable_Original(bnGmx).burn(_account, reductionAmount);
        }

        emit UnstakeGmx(_account, _amount);
    }
}
