import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { INotifyMock, IReentrancyProtectedMock } from "../../../typechain-types";

describe("ReentrancyGuard", async () =>
{
	// We define a fixture to reuse the same setup in every test.
	// We use loadFixture to run this setup once, snapshot that state,
	// and reset Hardhat Network to that snapshot in every test.
	async function deployReentrancyGuardFixture(): Promise<{ rpm: IReentrancyProtectedMock, goodNotify: INotifyMock, maliciousNotify: INotifyMock}>
	{
		const ReentrancyProtectedMockFactory = await ethers.getContractFactory("ReentrancyProtectedMock");
		const rpm = await ReentrancyProtectedMockFactory.deploy();

		const GoodNotifyFactory = await ethers.getContractFactory("GoodNotifyMock");
		const goodNotify = await GoodNotifyFactory.deploy();

		const MaliciousNotifyFactory = await ethers.getContractFactory("MaliciousNotifyMock");
		const maliciousNotify = await MaliciousNotifyFactory.deploy(rpm.address);

		return { rpm, goodNotify, maliciousNotify};
	}

	describe("IReentrancyGuard", async () =>
	{
		it("Should work with good contract", async () =>
		{
			const { rpm, goodNotify } = await loadFixture(deployReentrancyGuardFixture);

			const result = rpm.protected(goodNotify.address);

			await expect(result).to.be.not.reverted;
		});

		it("Should revert with malicious contract", async () =>
		{
			// eslint-disable-next-line @typescript-eslint/no-unused-vars
			const { rpm, goodNotify, maliciousNotify } = await loadFixture(deployReentrancyGuardFixture);

			const result = rpm.protected(maliciousNotify.address);

			await expect(result).to.be.revertedWithCustomError(rpm, "ReentrantCall");
		});
	});
});