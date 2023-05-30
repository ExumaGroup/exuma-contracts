// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ReentrancyGuard } from "../libraries/utils/ReentrancyGuard.sol";

interface INotifyMock
{
	function callMe() external;
}

interface IReentrancyProtectedMock
{
	function protected(INotifyMock toCall) external;
}

contract ReentrancyProtectedMock is ReentrancyGuard, IReentrancyProtectedMock {
	function protected(INotifyMock toCall) override external nonReentrant
	{ 
		toCall.callMe();
	}
}

contract GoodNotifyMock is INotifyMock
{
	function callMe() override external
	{} // solhint-disable-line no-empty-blocks
}

contract MaliciousNotifyMock is INotifyMock
{
	IReentrancyProtectedMock private immutable _rpm;

	constructor(IReentrancyProtectedMock rpm)
	{
		_rpm = rpm;
	}

	function callMe() override external
	{
		_rpm.protected(this);
	}
}