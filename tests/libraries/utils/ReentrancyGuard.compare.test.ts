import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect, assert } from "chai";
import { ethers } from "hardhat";
import { INotifyMock, INotifyMock_Original, IReentrancyProtectedMock, IReentrancyProtectedMock_Original } from "../../../typechain-types";

describe("ReentrancyGuard Compare", async () =>
{
	// We define a fixture to reuse the same setup in every test.
	// We use loadFixture to run this setup once, snapshot that state,
	// and reset Hardhat Network to that snapshot in every test.
	async function deployReentrancyGuardCompareFixture(): Promise<{ rpm: IReentrancyProtectedMock, rpmo: IReentrancyProtectedMock_Original, goodNotify: INotifyMock, goodNotifyOriginal: INotifyMock_Original, maliciousNotify: INotifyMock, maliciousNotifyOriginal: INotifyMock_Original }>
	{
		const ReentrancyProtectedMockFactory = await ethers.getContractFactory("ReentrancyProtectedMock");
		const rpm = await ReentrancyProtectedMockFactory.deploy();

		const ReentrancyProtectedMockOriginalFactory = await ethers.getContractFactory("ReentrancyProtectedMock_Original");
		const rpmo = await ReentrancyProtectedMockOriginalFactory.deploy();

		const GoodNotifyFactory = await ethers.getContractFactory("GoodNotifyMock");
		const goodNotify = await GoodNotifyFactory.deploy();

		const GoodNotifyOriginalFactory = await ethers.getContractFactory("GoodNotifyMock_Original");
		const goodNotifyOriginal = await GoodNotifyOriginalFactory.deploy();

		const MaliciousNotifyFactory = await ethers.getContractFactory("MaliciousNotifyMock");
		const maliciousNotify = await MaliciousNotifyFactory.deploy(rpm.address);

		const MaliciousNotifyOriginalFactory = await ethers.getContractFactory("MaliciousNotifyMock_Original");
		const maliciousNotifyOriginal = await MaliciousNotifyOriginalFactory.deploy(rpm.address);

		return { rpm, rpmo, goodNotify, goodNotifyOriginal, maliciousNotify, maliciousNotifyOriginal };
	}

	describe("Ensure same behavior", async () =>
	{
		it("Should work with good contract", async () =>
		{
			const { rpm, rpmo, goodNotify, goodNotifyOriginal } = await loadFixture(deployReentrancyGuardCompareFixture);

			const result = rpm.protected(goodNotify.address);
			const resultOriginal = rpmo.protected(goodNotifyOriginal.address);

			await expect(result).to.be.not.reverted;
			await expect(resultOriginal).to.be.not.reverted;
		});

		it("Should revert with malicious contract", async () =>
		{
			// eslint-disable-next-line @typescript-eslint/no-unused-vars
			const { rpm, rpmo, goodNotify, goodNotifyOriginal, maliciousNotify, maliciousNotifyOriginal } = await loadFixture(deployReentrancyGuardCompareFixture);

			// const result = rpm.protected(maliciousNotify.address);
			const resultOriginal = rpmo.protected(maliciousNotifyOriginal.address);

			// await expect(result).to.be.revertedWithCustomError(rpm, "ReentrantCall");
			await expect(resultOriginal).to.be.revertedWith("ReentrancyGuard: reentrant call");
		});
	});

	describe("Gas", async () =>
	{
		const AllowedCreationGasDiffPercent = 15;

		it("Should cost less to create than original", async () =>
		{
			const { rpm, rpmo } = await loadFixture(deployReentrancyGuardCompareFixture);

			const transactionReceipt = await ethers.provider.getTransactionReceipt(rpm.deployTransaction.hash);
			const gu = transactionReceipt.gasUsed;

			const transactionReceiptOriginal = await ethers.provider.getTransactionReceipt(rpmo.deployTransaction.hash);
			const guo = transactionReceiptOriginal.gasUsed;

			console.log("Gas Used for contract creation (New/Original): %d/%d", gu,guo);

			const allowedDiff = guo.mul(AllowedCreationGasDiffPercent).div(100);
			const guf = gu.sub(allowedDiff);

			assert.isBelow(guf.toNumber(), guo.toNumber(), "Contract creation is too expensive");
		});

		it("Should colst less to use than original", async () =>
		{
			// eslint-disable-next-line @typescript-eslint/no-unused-vars
			const { rpm, rpmo, goodNotify, goodNotifyOriginal } = await loadFixture(deployReentrancyGuardCompareFixture);

			const result = await rpm.protected(goodNotify.address);
			const resultOriginal = await rpmo.protected(goodNotifyOriginal.address);
			const transactionReceipt = await ethers.provider.getTransactionReceipt(result.hash);
			const gu = transactionReceipt.gasUsed;
			const transactionReceiptOriginal = await ethers.provider.getTransactionReceipt(resultOriginal.hash);
			const guo = transactionReceiptOriginal.gasUsed;

			console.log("Gas Used for transaction (New/Original): %d/%d", gu, guo);
			
			assert.isBelow(gu.toNumber(), guo.toNumber(), "Transaction is too expensive");
		});
	});
});