// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165_Original} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165_Original is IERC165_Original {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165_Original = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165_Original itself here
        _registerInterface(_INTERFACE_ID_ERC165_Original);
    }

    /**
     * @dev See {IERC165_Original-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165_Original interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165_Original-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165_Original invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165_Original: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}
