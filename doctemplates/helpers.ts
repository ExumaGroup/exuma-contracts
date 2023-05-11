import { ASTDereferencer, findAll } from "solidity-ast/utils";
import { DocItemContext, DocItemWithContext, DOC_ITEM_CONTEXT } from "solidity-docgen/dist/site";

export function allEvents(this: DocItemWithContext)
{
	if (this.nodeType === "ContractDefinition")
	{
		const deref: ASTDereferencer = this[DOC_ITEM_CONTEXT].build.deref;
		const parents = this.linearizedBaseContracts.map(deref("ContractDefinition"));

		const r = parents.flatMap(p => [...findAll("EventDefinition", p)]);
		// console.log(`Events: ${this.canonicalName} -> ${r.map(e => e.name)}`);
		return r.sort((a, b) => ((a.name ?? "") > (b.name ?? "")) ? 1 : -1);
	}
}

export function directParents(this: DocItemWithContext)
{
	if (this.nodeType === "ContractDefinition")
	{
		const deref: ASTDereferencer = this[DOC_ITEM_CONTEXT].build.deref;
		const parents = this.linearizedBaseContracts.filter(lbc => lbc !== this.id).map(deref("ContractDefinition"));

		const r = parents.flatMap(p => [{ name: p.canonicalName, docpath: extractDocPath((p as DocItemWithContext)[DOC_ITEM_CONTEXT]) }]);
		return r.sort((a, b) => ((a.name ?? "") > (b.name ?? "")) ? 1 : -1);
	}
}

export function fileHeader(this: DocItemWithContext)
{
	if (this.nodeType === "ContractDefinition")
	{
		const dic = this[DOC_ITEM_CONTEXT];
		if (!dic.page) return "**helpers.fileHeader:page property must be present!**";
		const purePath = extractDocPath(dic);

		let ret = "---\n";
		ret += `filename: ${purePath}\n`;
		ret += `type: ${dic.item.contractKind}\n`;
		ret += "---";
		return ret;
	}
}

function extractDocPath(dic: DocItemContext): string
{
	const regex = /\.md$/;
	if (!dic.page) return "/index";
	let result = dic.page.replace(regex, "");
	if (result[0] !== "/")
	{
		result = "/exuma-contracts/" + result;
	}
	return "/exuma-contracts" + result;
}
