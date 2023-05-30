// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITimelockTarget_Original {
    function setGov(address _gov) external;
    function withdrawToken_Original(address _token, address _account, uint256 _amount) external;
}
