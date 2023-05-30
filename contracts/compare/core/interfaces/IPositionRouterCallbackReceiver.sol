// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IPositionRouterCallbackReceiver_Original {
    function gmxPositionCallback(bytes32 positionKey, bool isExecuted, bool isIncrease) external;
}
