// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./BaseToken.sol";
import "./interfaces/IMintable.sol";

contract MintableBaseToken_Original is BaseToken_Original, IMintable_Original {

    mapping (address => bool) public override isMinter;

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) public BaseToken_Original(_name, _symbol, _initialSupply) {
    }

    modifier onlyMinter() {
        require(isMinter[msg.sender], "MintableBaseToken_Original: forbidden");
        _;
    }

    function setMinter(address _minter, bool _isActive) external override onlyGov {
        isMinter[_minter] = _isActive;
    }

    function mint(address _account, uint256 _amount) external override onlyMinter {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external override onlyMinter {
        _burn(_account, _amount);
    }
}
