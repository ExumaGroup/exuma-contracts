// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./MintableBaseToken.sol";

contract SnapshotToken_Original is MintableBaseToken_Original {
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) public MintableBaseToken_Original(_name, _symbol, _initialSupply) {
    }

    function batchMint(address[] memory _accounts, uint256[] memory _amounts) external onlyMinter {
        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            uint256 amount = _amounts[i];
            _mint(account, amount);
        }
    }
}
