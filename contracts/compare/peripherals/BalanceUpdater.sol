// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";
import "../core/interfaces/IVault.sol";

contract BalanceUpdater_Original {
    using SafeMath_Original for uint256;

    function updateBalance(
        address _vault,
        address _token,
        address _usdg,
        uint256 _usdgAmount
    ) public {
        IVault_Original vault = IVault_Original(_vault);
        IERC20_Original token = IERC20_Original(_token);
        uint256 poolAmount = vault.poolAmounts(_token);
        uint256 fee = vault.feeReserves(_token);
        uint256 balance = token.balanceOf(_vault);

        uint256 transferAmount = poolAmount.add(fee).sub(balance);
        token.transferFrom(msg.sender, _vault, transferAmount);
        IERC20_Original(_usdg).transferFrom(msg.sender, _vault, _usdgAmount);

        vault.sellUSDG(_token, msg.sender);
    }
}
