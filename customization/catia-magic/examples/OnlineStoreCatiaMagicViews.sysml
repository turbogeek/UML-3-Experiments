package OnlineStoreCatiaMagicViews {
	doc
	/*
	The online store's diagrams as CATIA Magic symbolic views with the UML3 palettes (UML3CatiaMagic). They
	expose the same content as the tool-neutral views of example 05, so the diagrams look the same, and they
	add palettes whose buttons create UML3 elements.

	Contents:
	- domainClasses: the class diagram of OnlineStoreDomain.
	- storePackages: the package diagram of the store's packages.
	- architectureComponents: the component diagram of OnlineStoreArchitecture.
	- deployment: the deployment diagram of the production cluster.
	- logicalDataModel: the entity relationship diagram of OnlineStoreDatabase.
	- messageSchemas: the message schema view of OnlineStoreMessaging.
	References: examples/05-OnlineStoreViews.sysml; UML3CatiaMagic; E17.
	*/

	private import UML3CatiaMagic::*;

	view domainClasses : 'UML3 Class Diagram' {
		doc /* The class diagram of the store's domain, drawn with the UML3 class palette. */
		expose OnlineStoreDomain::*;
	}

	view storePackages : 'UML3 Package Diagram' {
		doc /* The packages of the store model, drawn with the UML3 package palette. */
		expose OnlineStoreDomain::**;
	}

	view architectureComponents : 'UML3 Component Diagram' {
		doc /* The store's components and their wiring, drawn with the UML3 component palette. */
		expose OnlineStoreArchitecture::*;
	}

	view deployment : 'UML3 Deployment Diagram' {
		doc /* The store's deployment, drawn with the UML3 deployment palette. */
		expose OnlineStoreArchitecture::**;
	}

	view logicalDataModel : 'UML3 Entity Relationship Diagram' {
		doc /* The store's data model, drawn with the UML3 data palette. */
		expose OnlineStoreDatabase::*;
	}

	view messageSchemas : 'UML3 Message Schema View' {
		doc /* The store's message schemas, drawn with the UML3 messaging palette. */
		expose OnlineStoreMessaging::*;
	}
}
