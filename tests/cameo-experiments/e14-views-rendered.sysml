package UML3E14RenderedViews {
	doc
	/*
	E14 run B: the nine views of examples/05-OnlineStoreViews.sysml with an explicit rendering, to measure whether
	the rendering gives CATIA Magic a display mode that lays out the diagram without overlapping shapes.
	Contents:
	- Tree-rendered views: domainClassDiagram, storePackages, deploymentDiagram, logicalDataModel, physicalSchema,
	  messageSchemas, checkoutSequence (render asTreeDiagram).
	- Interconnection-rendered view: architectureComponents (render asInterconnectionDiagram).
	- Table-rendered view: domainClassTable (render asElementTable).
	References: SysML 7.26; E13; E14.
	*/
	private import Views::*;
	private import UML3Views::*;

	view domainClassDiagram : ClassDiagram {
		doc /* The domain class diagram of example 05, rendered as a tree diagram. */
		render asTreeDiagram;
		expose OnlineStoreDomain::*;
	}
	view storePackages : PackageDiagram {
		doc /* The package diagram of example 05, rendered as a tree diagram. */
		render asTreeDiagram;
		expose OnlineStoreDatabase::*;
	}
	view architectureComponents : ComponentDiagram {
		doc /* The component diagram of example 05, rendered as an interconnection diagram. */
		render asInterconnectionDiagram;
		expose OnlineStoreArchitecture::*;
	}
	view deploymentDiagram : DeploymentDiagram {
		doc /* The deployment diagram of example 05, rendered as a tree diagram. */
		render asTreeDiagram;
		expose OnlineStoreArchitecture::*;
	}
	view logicalDataModel : EntityRelationshipDiagram {
		doc /* The logical data model of example 05, rendered as a tree diagram. */
		render asTreeDiagram;
		expose OnlineStoreDatabase::Logical::*;
	}
	view physicalSchema : EntityRelationshipDiagram {
		doc /* The physical schema of example 05, rendered as a tree diagram. */
		render asTreeDiagram;
		expose OnlineStoreDatabase::Physical::*;
	}
	view messageSchemas : MessageSchemaView {
		doc /* The message schema view of example 05, rendered as a tree diagram. */
		render asTreeDiagram;
		expose OnlineStoreMessaging::*;
	}
	view checkoutSequence : SequenceDiagram {
		doc /* The checkout sequence of example 05, rendered as a tree diagram. */
		render asTreeDiagram;
		expose OnlineStoreMessaging::CheckoutInteraction;
	}
	view domainClassTable : ClassTable {
		doc /* The domain class table of example 05, rendered as an element table. */
		render asElementTable;
		expose OnlineStoreDomain::*;
	}
}
