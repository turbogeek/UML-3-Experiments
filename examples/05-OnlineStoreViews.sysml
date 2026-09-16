package OnlineStoreViews {
	doc
	/*
	 * Example 5 - UML-style diagrams of the online store as SysML v2 views (UML3Views).
	 * Each view exposes a part of the model; the view definition's filter picks the
	 * elements that belong on that kind of diagram.
	 */
	private import UML3Views::*;

	view domainClassDiagram : ClassDiagram {
		expose OnlineStoreDomain::*;
	}

	view storePackages : PackageDiagram {
		expose OnlineStoreDatabase::*;
	}

	view architectureComponents : ComponentDiagram {
		expose OnlineStoreArchitecture::*;
	}

	view deploymentDiagram : DeploymentDiagram {
		expose OnlineStoreArchitecture::*;
	}

	view logicalDataModel : EntityRelationshipDiagram {
		expose OnlineStoreDatabase::Logical::*;
	}

	view physicalSchema : EntityRelationshipDiagram {
		expose OnlineStoreDatabase::Physical::*;
	}

	view messageSchemas : MessageSchemaView {
		expose OnlineStoreMessaging::*;
	}

	view checkoutSequence : SequenceDiagram {
		expose OnlineStoreMessaging::CheckoutInteraction;
	}

	view domainClassTable : ClassTable {
		expose OnlineStoreDomain::*;
	}
}
