// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IRewardDistributor.sol";
import "./interfaces/IRewardTracker.sol";
import "../access/Governable.sol";

contract BonusDistributor_Original is IRewardDistributor_Original, ReentrancyGuard_Original, Governable_Original {
    using SafeMath_Original for uint256;
    using SafeERC20_Original for IERC20_Original;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant BONUS_DURATION = 365 days;

    uint256 public bonusMultiplierBasisPoints;

    address public override rewardToken;
    uint256 public lastDistributionTime;
    address public rewardTracker;

    address public admin;

    event Distribute(uint256 amount);
    event BonusMultiplierChange(uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "BonusDistributor: forbidden");
        _;
    }

    constructor(address _rewardToken, address _rewardTracker) public {
        rewardToken = _rewardToken;
        rewardTracker = _rewardTracker;
        admin = msg.sender;
    }

    function setAdmin(address _admin) external onlyGov {
        admin = _admin;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken_Original(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20_Original(_token).safeTransfer(_account, _amount);
    }

    function updateLastDistributionTime() external onlyAdmin {
        lastDistributionTime = block.timestamp;
    }

    function setBonusMultiplier(uint256 _bonusMultiplierBasisPoints) external onlyAdmin {
        require(lastDistributionTime != 0, "BonusDistributor: invalid lastDistributionTime");
        IRewardTracker_Original(rewardTracker).updateRewards();
        bonusMultiplierBasisPoints = _bonusMultiplierBasisPoints;
        emit BonusMultiplierChange(_bonusMultiplierBasisPoints);
    }

    function tokensPerInterval() public view override returns (uint256) {
        uint256 supply = IERC20_Original(rewardTracker).totalSupply();
        return supply.mul(bonusMultiplierBasisPoints).div(BASIS_POINTS_DIVISOR).div(BONUS_DURATION);
    }

    function pendingRewards() public view override returns (uint256) {
        if (block.timestamp == lastDistributionTime) {
            return 0;
        }

        uint256 supply = IERC20_Original(rewardTracker).totalSupply();
        uint256 timeDiff = block.timestamp.sub(lastDistributionTime);

        return timeDiff.mul(supply).mul(bonusMultiplierBasisPoints).div(BASIS_POINTS_DIVISOR).div(BONUS_DURATION);
    }

    function distribute() external override returns (uint256) {
        require(msg.sender == rewardTracker, "BonusDistributor: invalid msg.sender");
        uint256 amount = pendingRewards();
        if (amount == 0) { return 0; }

        lastDistributionTime = block.timestamp;

        uint256 balance = IERC20_Original(rewardToken).balanceOf(address(this));
        if (amount > balance) { amount = balance; }

        IERC20_Original(rewardToken).safeTransfer(msg.sender, amount);

        emit Distribute(amount);
        return amount;
    }
}
