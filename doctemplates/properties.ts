import { isNodeType } from "solidity-ast/utils";
import { slug } from "./helpers";

export function anchor({item, contract}): string
{
	let res = "";
	if(contract)
	{
		res += contract.name + "-";
	}
	res += item.name;
	if ("parameters" in item)
	{
		const signature = item.parameters.parameters.map(v => v.typeName.typeDescriptions.typeString).join(",");
		res += slug("(" + signature + ")");
	}
	if (isNodeType("VariableDeclaration", item))
	{
		res += "-" + slug(item.typeName.typeDescriptions.typeString);
	}
	return res;
}