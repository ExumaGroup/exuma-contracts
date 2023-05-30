// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../Vault.sol";

contract VaultTest_Original is Vault_Original {
    function increaseGlobalShortSize(address token, uint256 amount) external {
        _increaseGlobalShortSize(token, amount);
    }
}
