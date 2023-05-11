const pathPrefix = process.env.NODE_ENV === "production" ? "/exuma-contracts" : "";

module.exports = {
	assetPrefix: pathPrefix,
	env: {
		pathPrefix
	},
};