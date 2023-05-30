// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "../access/Governable.sol";

contract Bridge_Original is ReentrancyGuard_Original, Governable_Original {
    using SafeMath_Original for uint256;
    using SafeERC20_Original for IERC20_Original;

    address public token;
    address public wToken;

    constructor(address _token, address _wToken) public {
        token = _token;
        wToken = _wToken;
    }

    function wrap(uint256 _amount, address _receiver) external nonReentrant {
        IERC20_Original(token).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20_Original(wToken).safeTransfer(_receiver, _amount);
    }

    function unwrap(uint256 _amount, address _receiver) external nonReentrant {
        IERC20_Original(wToken).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20_Original(token).safeTransfer(_receiver, _amount);
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken_Original(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20_Original(_token).safeTransfer(_account, _amount);
    }
}
