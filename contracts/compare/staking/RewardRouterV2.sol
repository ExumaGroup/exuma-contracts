// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";
import "../libraries/utils/Address.sol";

import "./interfaces/IRewardTracker.sol";
import "./interfaces/IRewardRouterV2.sol";
import "./interfaces/IVester.sol";
import "../tokens/interfaces/IMintable.sol";
import "../tokens/interfaces/IWETH.sol";
import "../core/interfaces/IGlpManager.sol";
import "../access/Governable.sol";

contract RewardRouterV2_Original is IRewardRouterV2_Original, ReentrancyGuard_Original, Governable_Original {
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

    address public override stakedGlpTracker;
    address public override feeGlpTracker;

    address public glpManager;

    address public gmxVester;
    address public glpVester;

    mapping (address => address) public pendingReceivers;

    event StakeGmx(address account, address token, uint256 amount);
    event UnstakeGmx(address account, address token, uint256 amount);

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
        address _glpManager,
        address _gmxVester,
        address _glpVester
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

        gmxVester = _gmxVester;
        glpVester = _glpVester;
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
        _unstakeGmx(msg.sender, gmx, _amount, true);
    }

    function unstakeEsGmx(uint256 _amount) external nonReentrant {
        _unstakeGmx(msg.sender, esGmx, _amount, true);
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

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external nonReentrant {
        address account = msg.sender;

        uint256 gmxAmount = 0;
        if (_shouldClaimGmx) {
            uint256 gmxAmount0 = IVester_Original(gmxVester).claimForAccount(account, account);
            uint256 gmxAmount1 = IVester_Original(glpVester).claimForAccount(account, account);
            gmxAmount = gmxAmount0.add(gmxAmount1);
        }

        if (_shouldStakeGmx && gmxAmount > 0) {
            _stakeGmx(account, account, gmx, gmxAmount);
        }

        uint256 esGmxAmount = 0;
        if (_shouldClaimEsGmx) {
            uint256 esGmxAmount0 = IRewardTracker_Original(stakedGmxTracker).claimForAccount(account, account);
            uint256 esGmxAmount1 = IRewardTracker_Original(stakedGlpTracker).claimForAccount(account, account);
            esGmxAmount = esGmxAmount0.add(esGmxAmount1);
        }

        if (_shouldStakeEsGmx && esGmxAmount > 0) {
            _stakeGmx(account, account, esGmx, esGmxAmount);
        }

        if (_shouldStakeMultiplierPoints) {
            uint256 bnGmxAmount = IRewardTracker_Original(bonusGmxTracker).claimForAccount(account, account);
            if (bnGmxAmount > 0) {
                IRewardTracker_Original(feeGmxTracker).stakeForAccount(account, account, bnGmx, bnGmxAmount);
            }
        }

        if (_shouldClaimWeth) {
            if (_shouldConvertWethToEth) {
                uint256 weth0 = IRewardTracker_Original(feeGmxTracker).claimForAccount(account, address(this));
                uint256 weth1 = IRewardTracker_Original(feeGlpTracker).claimForAccount(account, address(this));

                uint256 wethAmount = weth0.add(weth1);
                IWETH_Original(weth).withdraw(wethAmount);

                payable(account).sendValue(wethAmount);
            } else {
                IRewardTracker_Original(feeGmxTracker).claimForAccount(account, account);
                IRewardTracker_Original(feeGlpTracker).claimForAccount(account, account);
            }
        }
    }

    function batchCompoundForAccounts(address[] memory _accounts) external nonReentrant onlyGov {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _compound(_accounts[i]);
        }
    }

    // the _validateReceiver function checks that the averageStakedAmounts and cumulativeRewards
    // values of an account are zero, this is to help ensure that vesting calculations can be
    // done correctly
    // averageStakedAmounts and cumulativeRewards are updated if the claimable reward for an account
    // is more than zero
    // it is possible for multiple transfers to be sent into a single account, using signalTransfer and
    // acceptTransfer, if those values have not been updated yet
    // for GLP transfers it is also possible to transfer GLP into an account using the StakedGlp contract
    function signalTransfer(address _receiver) external nonReentrant {
        require(IERC20_Original(gmxVester).balanceOf(msg.sender) == 0, "RewardRouter: sender has vested tokens");
        require(IERC20_Original(glpVester).balanceOf(msg.sender) == 0, "RewardRouter: sender has vested tokens");

        _validateReceiver(_receiver);
        pendingReceivers[msg.sender] = _receiver;
    }

    function acceptTransfer(address _sender) external nonReentrant {
        require(IERC20_Original(gmxVester).balanceOf(_sender) == 0, "RewardRouter: sender has vested tokens");
        require(IERC20_Original(glpVester).balanceOf(_sender) == 0, "RewardRouter: sender has vested tokens");

        address receiver = msg.sender;
        require(pendingReceivers[_sender] == receiver, "RewardRouter: transfer not signalled");
        delete pendingReceivers[_sender];

        _validateReceiver(receiver);
        _compound(_sender);

        uint256 stakedGmx = IRewardTracker_Original(stakedGmxTracker).depositBalances(_sender, gmx);
        if (stakedGmx > 0) {
            _unstakeGmx(_sender, gmx, stakedGmx, false);
            _stakeGmx(_sender, receiver, gmx, stakedGmx);
        }

        uint256 stakedEsGmx = IRewardTracker_Original(stakedGmxTracker).depositBalances(_sender, esGmx);
        if (stakedEsGmx > 0) {
            _unstakeGmx(_sender, esGmx, stakedEsGmx, false);
            _stakeGmx(_sender, receiver, esGmx, stakedEsGmx);
        }

        uint256 stakedBnGmx = IRewardTracker_Original(feeGmxTracker).depositBalances(_sender, bnGmx);
        if (stakedBnGmx > 0) {
            IRewardTracker_Original(feeGmxTracker).unstakeForAccount(_sender, bnGmx, stakedBnGmx, _sender);
            IRewardTracker_Original(feeGmxTracker).stakeForAccount(_sender, receiver, bnGmx, stakedBnGmx);
        }

        uint256 esGmxBalance = IERC20_Original(esGmx).balanceOf(_sender);
        if (esGmxBalance > 0) {
            IERC20_Original(esGmx).transferFrom(_sender, receiver, esGmxBalance);
        }

        uint256 glpAmount = IRewardTracker_Original(feeGlpTracker).depositBalances(_sender, glp);
        if (glpAmount > 0) {
            IRewardTracker_Original(stakedGlpTracker).unstakeForAccount(_sender, feeGlpTracker, glpAmount, _sender);
            IRewardTracker_Original(feeGlpTracker).unstakeForAccount(_sender, glp, glpAmount, _sender);

            IRewardTracker_Original(feeGlpTracker).stakeForAccount(_sender, receiver, glp, glpAmount);
            IRewardTracker_Original(stakedGlpTracker).stakeForAccount(receiver, receiver, feeGlpTracker, glpAmount);
        }

        IVester_Original(gmxVester).transferStakeValues(_sender, receiver);
        IVester_Original(glpVester).transferStakeValues(_sender, receiver);
    }

    function _validateReceiver(address _receiver) private view {
        require(IRewardTracker_Original(stakedGmxTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: stakedGmxTracker.averageStakedAmounts > 0");
        require(IRewardTracker_Original(stakedGmxTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: stakedGmxTracker.cumulativeRewards > 0");

        require(IRewardTracker_Original(bonusGmxTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: bonusGmxTracker.averageStakedAmounts > 0");
        require(IRewardTracker_Original(bonusGmxTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: bonusGmxTracker.cumulativeRewards > 0");

        require(IRewardTracker_Original(feeGmxTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: feeGmxTracker.averageStakedAmounts > 0");
        require(IRewardTracker_Original(feeGmxTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: feeGmxTracker.cumulativeRewards > 0");

        require(IVester_Original(gmxVester).transferredAverageStakedAmounts(_receiver) == 0, "RewardRouter: gmxVester.transferredAverageStakedAmounts > 0");
        require(IVester_Original(gmxVester).transferredCumulativeRewards(_receiver) == 0, "RewardRouter: gmxVester.transferredCumulativeRewards > 0");

        require(IRewardTracker_Original(stakedGlpTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: stakedGlpTracker.averageStakedAmounts > 0");
        require(IRewardTracker_Original(stakedGlpTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: stakedGlpTracker.cumulativeRewards > 0");

        require(IRewardTracker_Original(feeGlpTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: feeGlpTracker.averageStakedAmounts > 0");
        require(IRewardTracker_Original(feeGlpTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: feeGlpTracker.cumulativeRewards > 0");

        require(IVester_Original(glpVester).transferredAverageStakedAmounts(_receiver) == 0, "RewardRouter: gmxVester.transferredAverageStakedAmounts > 0");
        require(IVester_Original(glpVester).transferredCumulativeRewards(_receiver) == 0, "RewardRouter: gmxVester.transferredCumulativeRewards > 0");

        require(IERC20_Original(gmxVester).balanceOf(_receiver) == 0, "RewardRouter: gmxVester.balance > 0");
        require(IERC20_Original(glpVester).balanceOf(_receiver) == 0, "RewardRouter: glpVester.balance > 0");
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

        emit StakeGmx(_account, _token, _amount);
    }

    function _unstakeGmx(address _account, address _token, uint256 _amount, bool _shouldReduceBnGmx) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        uint256 balance = IRewardTracker_Original(stakedGmxTracker).stakedAmounts(_account);

        IRewardTracker_Original(feeGmxTracker).unstakeForAccount(_account, bonusGmxTracker, _amount, _account);
        IRewardTracker_Original(bonusGmxTracker).unstakeForAccount(_account, stakedGmxTracker, _amount, _account);
        IRewardTracker_Original(stakedGmxTracker).unstakeForAccount(_account, _token, _amount, _account);

        if (_shouldReduceBnGmx) {
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
        }

        emit UnstakeGmx(_account, _token, _amount);
    }
}
