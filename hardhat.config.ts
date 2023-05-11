import "@nomicfoundation/hardhat-toolbox";
import "hardhat-abi-exporter";
import "hardhat-contract-sizer";
import "solidity-docgen";

import * as dotenv from "dotenv";
dotenv.config();

import { PageAssigner } from "solidity-docgen/dist/site";
const excludePath: RegExp[] = [/\/mocks\//, /\/compare\//];
const pa: PageAssigner = (item, file, config) =>
{
	for (const excludeMe of excludePath)
	{
		if (excludeMe.test(file.absolutePath))
		{
			return undefined;
		}
	}
	return file.absolutePath.replace(".sol", config.pageExtension);
};

const accounts = {
	mnemonic:
		process.env.MNEMONIC ||
		"test test test test test test test test test test test junk"
	// accountsBalance: ethers.utils.parseEther("1");
};

const config = {
	abiExporter:
		[
			{
				runOnCompile: true,
				path: "./abi/json",
				clear: true,
				flat: false,
				format: "json"
			},
			{
				runOnCompile: true,
				path: "./abi/compact",
				clear: true,
				flat: false,
				format: "fullName"
			}
		],
	contractSizer:
	{
		runOnCompile: true,
		except: ["contracts/mocks/*"]
	},
	docgen: {
		pages: pa, // "files",
		templates: "doctemplates"
	},
	etherscan: { apiKey: process.env.ETHERSCAN_API_KEY },
	gasReporter:
	{
		enabled: process.env.REPORT_GAS === "true",
		coinmarketcap: process.env.COINMARKETCAP_API_KEY,
		currency: "EUR",
		excludeContracts:
			[
				"contracts/mocks/"
			]
	},
	networks: {
		goerli: {
			url: `https://eth-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
			accounts
		}
	},
	solidity: {
		compilers: [
			{
				version: "0.8.19",
				settings:
				{
					optimizer:
					{
						enabled: true,
						runs: 500000
					}
				}
			},
			{
				version: "0.6.12",
				settings:
				{
					optimizer:
					{
						enabled: true,
						runs: 10
					}
				}
			}
		]
	}
};

export default config;
