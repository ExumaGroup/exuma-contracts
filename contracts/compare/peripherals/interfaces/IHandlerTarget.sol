// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IHandlerTarget_Original {
    function isHandler(address _account) external returns (bool);
    function setHandler(address _handler, bool _isActive) external;
}
