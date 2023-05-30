// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../tokens/MintableBaseToken.sol";

contract GMX_Original is MintableBaseToken_Original {
    constructor() public MintableBaseToken_Original("GMX", "GMX", 0) {
    }

    function id() external pure returns (string memory _name) {
        return "GMX";
    }
}
