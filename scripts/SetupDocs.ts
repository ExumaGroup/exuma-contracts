import fs from "fs";
import path from "path";

function main()
{
	const rootFolder = path.join(__dirname, "..");
	const docsFolder = path.join(rootFolder, "docs");
	const docsCoverageFolder = path.join(docsFolder, "coverage");
	const coverageFolder = path.join(rootFolder, "coverage");
	const docstaticsFolder = path.join(rootFolder, "docstatics");

	// Clean up docs folder
	if(fs.existsSync(docsFolder))
	{
		fs.rmSync(docsFolder, { recursive: true, force: true });
	}
	fs.mkdirSync(docsFolder);
	fs.mkdirSync(docsCoverageFolder);

	// Copy contracts to package folder
	fs.cpSync(docstaticsFolder, docsFolder, { force: true, recursive: true });
	fs.cpSync(coverageFolder, docsCoverageFolder, { force: true, recursive: true });
}

main();

