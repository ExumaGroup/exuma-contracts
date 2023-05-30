// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRewardRouterV2_Original {
    function feeGlpTracker() external view returns (address);
    function stakedGlpTracker() external view returns (address);
}
