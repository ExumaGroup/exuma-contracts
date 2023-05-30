// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/IRewardTracker.sol";
import "../access/Governable.sol";

contract StakeManager_Original is Governable_Original {
    function stakeForAccount(
        address _rewardTracker,
        address _account,
        address _token,
        uint256 _amount
    ) external onlyGov {
        IRewardTracker_Original(_rewardTracker).stakeForAccount(_account, _account, _token, _amount);
    }
}
