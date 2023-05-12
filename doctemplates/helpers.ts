import { ASTDereferencer, findAll } from "solidity-ast/utils";
import { DocItemContext, DocItemWithContext, DOC_ITEM_CONTEXT } from "solidity-docgen/dist/site";

export function smartJoinLines(text?: string, paragraphWrap?: string)
{
	if (typeof text === "string")
	{
		// First replace all CR+LF with LF
		let modifiedText = text.replace(/\r\n/g, "\n");
		// Replace all LF that not followed by one ore more LF with a singe space
		modifiedText = modifiedText.replace(/\n([^\n])/g, " $1");
		// Replace all multible LFs with a singe LF
		modifiedText = modifiedText.replace(/\n\n+/g, "\n");
		// Replace multible white spaces and tabs with a single space
		modifiedText = modifiedText.replace(/[ \t][ \t]+/g, " ");
		// Replace LF followed by space with double LF
		modifiedText = modifiedText.replace(/\n /g, "\n\n");
		if(paragraphWrap !== null && paragraphWrap !== undefined && typeof paragraphWrap === "string")
		{
			modifiedText = paragraphWrap + modifiedText.replace(/\n\n/g, paragraphWrap + "\n\n" + paragraphWrap) + paragraphWrap;
		}
		return modifiedText;
	}
}

export function allConstructors(this: DocItemWithContext)
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
		result = "/" + result;
	}
	return "/exuma-contracts" + result;
}
