// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../compare/libraries/utils/ReentrancyGuard.sol";

interface INotifyMock_Original
{
	function callMe() external;
}

interface IReentrancyProtectedMock_Original
{
	function protected(INotifyMock_Original toCall) external;
}

contract ReentrancyProtectedMock_Original is ReentrancyGuard_Original, IReentrancyProtectedMock_Original {
	function protected(INotifyMock_Original toCall) override external nonReentrant
	{ 
		toCall.callMe();
	}
}

contract GoodNotifyMock_Original is INotifyMock_Original
{
	function callMe() override external
	{} // solhint-disable-line no-empty-blocks
}

contract MaliciousNotifyMock_Original is INotifyMock_Original
{
	IReentrancyProtectedMock_Original private immutable _rpm;

	constructor(IReentrancyProtectedMock_Original rpm) public
	{
		_rpm = rpm;
	}

	function callMe() override external
	{
		_rpm.protected(this);
	}
}