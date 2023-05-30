// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./YieldToken.sol";

contract YieldFarm_Original is YieldToken_Original, ReentrancyGuard_Original {
    using SafeERC20_Original for IERC20_Original;

    address public stakingToken;

    constructor(string memory _name, string memory _symbol, address _stakingToken) public YieldToken_Original(_name, _symbol, 0) {
        stakingToken = _stakingToken;
    }

    function stake(uint256 _amount) external nonReentrant {
        IERC20_Original(stakingToken).safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external nonReentrant {
        _burn(msg.sender, _amount);
        IERC20_Original(stakingToken).safeTransfer(msg.sender, _amount);
    }
}
