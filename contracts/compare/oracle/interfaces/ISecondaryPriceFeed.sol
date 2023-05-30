// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ISecondaryPriceFeed_Original {
    function getPrice(address _token, uint256 _referencePrice, bool _maximise) external view returns (uint256);
}
