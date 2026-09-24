package OnlineStoreCatiaMagicViews {
	doc
	/*
	The online store's diagrams as CATIA Magic symbolic views with the UML3 palettes (UML3CatiaMagic). They
	expose the same content as the tool-neutral views of example 05, so the diagrams look the same, and they
	add palettes whose buttons create UML3 elements.

	Contents:
	- domainClasses: the class diagram of OnlineStoreDomain.
	- storePackages: the package diagram of the data model's packages.
	- architectureComponents: the component diagram of OnlineStoreArchitecture.
	- deployment: the deployment diagram of the production cluster.
	- logicalDataModel: the entity relationship diagram of the logical data model.
	- messageSchemas: the message schema view of OnlineStoreMessaging.
	- domainClassDetails, deploymentDetails, logicalDataModelDetails, messageSchemaDetails: the same content
	  with compartments, which the UML3 detail style sheet makes visible on a view that has a palette (E19).
	References: examples/05-OnlineStoreViews.sysml; UML3CatiaMagic; E17.
	*/

	private import UML3CatiaMagic::*;

	view domainClasses : 'UML3 Class Diagram' {
		doc /* The class diagram of the store's domain, drawn with the UML3 class palette. */
		expose OnlineStoreDomain::*;
	}

	view storePackages : 'UML3 Package Diagram' {
		doc /* The packages of the store's data model, drawn with the UML3 package palette (as in example 05). */
		expose OnlineStoreDatabase::*;
	}

	view architectureComponents : 'UML3 Component Diagram' {
		doc /* The store's components and their wiring, drawn with the UML3 component palette. */
		expose OnlineStoreArchitecture::*;
	}

	view deployment : 'UML3 Deployment Diagram' {
		doc /* The store's deployment, drawn with the UML3 deployment palette (same expose as example 05). */
		expose OnlineStoreArchitecture::*;
	}

	view logicalDataModel : 'UML3 Entity Relationship Diagram' {
		doc /* The store's logical data model, drawn with the UML3 data palette (same expose as example 05). */
		expose OnlineStoreDatabase::Logical::*;
	}

	view messageSchemas : 'UML3 Message Schema View' {
		doc /* The store's message schemas, drawn with the UML3 messaging palette. */
		expose OnlineStoreMessaging::*;
	}

	view domainClassDetails : 'UML3 Class Detail Diagram' {
		doc /* The class diagram of the store's domain with compartments, drawn with the UML3 class palette. */
		expose OnlineStoreDomain::*;
	}

	view deploymentDetails : 'UML3 Deployment Detail Diagram' {
		doc /* The store's deployment with compartments, drawn with the UML3 deployment palette. */
		expose OnlineStoreArchitecture::*;
	}

	view logicalDataModelDetails : 'UML3 Entity Relationship Detail Diagram' {
		doc /* The logical data model with columns and keys, drawn with the UML3 data palette. */
		expose OnlineStoreDatabase::Logical::*;
	}

	view messageSchemaDetails : 'UML3 Message Schema Detail View' {
		doc /* The message schemas with payload attributes, drawn with the UML3 messaging palette. */
		expose OnlineStoreMessaging::*;
	}

	view domainClassTable : 'UML3 Class Table' {
		doc
		/*
		The store's classifiers as a table, one row each, with name, documentation and qualified name.

		The tool-neutral OnlineStoreViews::domainClassTable exposes the same content but names no columns, so
		CATIA Magic opens it with the right number of rows and nothing in them (I-44). This is the form that
		reads.
		*/
		expose OnlineStoreDomain::*;
	}
}
