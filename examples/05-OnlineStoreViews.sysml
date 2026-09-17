package OnlineStoreViews {
	doc
	/*
	Example 5: the UML diagrams of the online store, declared as SysML v2 views of the other examples.

	A view usage only says what to show: it exposes a package or an element, and the filters of its
	UML3Views definition keep the elements that belong on that kind of diagram, recognized by their UML3
	keywords, and hide the library elements that imports would bring in (E06). The same diagram kind
	therefore selects the same kinds of elements wherever it is used. The content named in each view's
	doc is what CATIA Magic 2026x returned as the view's exposed elements; opening a view there as a drawn
	diagram is not yet verified (E07).

	Contents:
	- Domain classes: domainClassDiagram (ClassDiagram) and domainClassTable (ClassTable) of OnlineStoreDomain.
	- Packages: storePackages (PackageDiagram) of OnlineStoreDatabase.
	- Architecture: architectureComponents (ComponentDiagram) and deploymentDiagram (DeploymentDiagram) of
	  OnlineStoreArchitecture.
	- Data: logicalDataModel and physicalSchema (EntityRelationshipDiagram) of OnlineStoreDatabase.
	- Messaging: messageSchemas (MessageSchemaView) of OnlineStoreMessaging, and checkoutSequence
	  (SequenceDiagram) of its CheckoutInteraction.
	References: UML3Views::ClassDiagram; SysML 7.26.2; SysML 9.2.20; E06; E07.
	*/
	private import UML3Views::*;

	view domainClassDiagram : ClassDiagram {
		doc
		/*
		UML class diagram of the domain model: the classes, interfaces, value types, enumeration, exception,
		associations, template and dependencies of OnlineStoreDomain.

		It exposes the package's direct members; ClassDiagram keeps the elements that have a class diagram
		keyword, and the enumerations, while attributes and operations stay inside their classes. Observed
		content: 22 elements, among them Customer, Order, PaymentGateway, the associations Places, Review
		and Contains, and the dependencies checkoutUsesGateway and repositoryCreatesCustomers.
		Rationale: this is the vocabulary that the architecture, messaging, database and behavior examples
		build on, so it is the first diagram a reader needs.
		References: UML 2.5.1 Class diagram; UML3Views::ClassDiagram; SysML 7.26.2.
		*/
		expose OnlineStoreDomain::*;
	}

	view storePackages : PackageDiagram {
		doc
		/*
		UML package diagram of the database example: the packages Logical and Physical of OnlineStoreDatabase.

		PackageDiagram keeps only packages. Exposing the direct members is enough here, because Logical and
		Physical contain no further packages; deeper package trees need a recursive expose (P::**).
		Observed content: Logical and Physical.
		Rationale: it shows at a glance the split between the logical data model and the physical schema.
		References: UML 2.5.1 Package diagram; UML3Views::PackageDiagram; SysML 7.26.2.
		*/
		expose OnlineStoreDatabase::*;
	}

	view architectureComponents : ComponentDiagram {
		doc
		/*
		UML component diagram of the store architecture: the storefront and services, the StoreSystem
		subsystem, the service port definitions and the interfaces behind them.

		ComponentDiagram keeps components, services, subsystems, interfaces, ports and connections, and uses
		the interconnection rendering. Observed content: 9 elements, OrderManagement, OrderApiPort,
		PaymentApiPort, WebStorefront, OrderService, PaymentService and StoreSystem, plus the domain
		interfaces PaymentGateway and Auditable, which OnlineStoreArchitecture imports. Artifacts, nodes,
		layers and the production cluster are not selected; deploymentDiagram shows the deployment.
		Rationale: it shows that the services depend on each other only through ports typed by contracts.
		References: UML 2.5.1 Component diagram; UML3Views::ComponentDiagram; SysML 7.26.2; E06.
		*/
		expose OnlineStoreArchitecture::*;
	}

	view deploymentDiagram : DeploymentDiagram {
		doc
		/*
		UML deployment diagram of the store: the image, runtime environment, machines and network on which
		the order service runs.

		It exposes the same package as architectureComponents, and DeploymentDiagram keeps only the
		deployment keywords, so one package yields both the component and the deployment picture. Observed
		content: the artifact OrderServiceImage, the execution environment KubernetesPod, the device
		WorkerNode and the communication path ClusterNetwork. The #manifest and #deploy allocations are
		owned by productionCluster, below the exposed members, so they are not in this view; selecting them
		would need a recursive expose.
		Rationale: it keeps what is deployed, and where, apart from how the software is structured.
		References: UML 2.5.1 Deployment diagram; UML3Views::DeploymentDiagram; SysML 7.26.2.
		*/
		expose OnlineStoreArchitecture::*;
	}

	view logicalDataModel : EntityRelationshipDiagram {
		doc
		/*
		Entity-relationship diagram of the logical data model, OnlineStoreDatabase::Logical.

		UML has no diagram of this kind; UML draws a data model as a class diagram. Observed content:
		PostalAddress, CustomerAccount, PurchaseOrder, PurchaseOrderLine, Tag, AccountOrders and
		OrderTagging.
		Rationale: exposing only the Logical package keeps tables and SQL details out of the business view
		of the data.
		References: UML3Views::EntityRelationshipDiagram; UML3Data::Entity; SysML 7.26.2.
		*/
		expose OnlineStoreDatabase::Logical::*;
	}

	view physicalSchema : EntityRelationshipDiagram {
		doc
		/*
		Physical schema diagram of the store database, OnlineStoreDatabase::Physical.

		It uses the same view definition as logicalDataModel: EntityRelationshipDiagram selects both logical
		and physical keywords, and the exposed package decides which level is shown. Observed content:
		StoreDb, CUSTOMER_ACCOUNT, PURCHASE_ORDER, OPEN_ORDERS_V and the #mapsTo dependencies
		customerMapping and orderMapping.
		Rationale: tables, keys and the mapping back to the logical model are reviewed together.
		References: UML3Views::EntityRelationshipDiagram; UML3Data::Table; UML3Data::MapsTo; SysML 7.26.2.
		*/
		expose OnlineStoreDatabase::Physical::*;
	}

	view messageSchemas : MessageSchemaView {
		doc
		/*
		Message schema view of the event-driven design: the message types, the topic and the broker of
		OnlineStoreMessaging.

		UML has no diagram of this kind; it corresponds to a class diagram of message payloads and channels.
		Observed content: the domain events OrderPlaced and PaymentCaptured, the command CapturePayment, the
		reply PaymentResult, the topic OrderEventsTopic and the broker KafkaCluster. Ports, services, the
		wiring and the interaction are not selected; the interaction has its own view, checkoutSequence.
		Rationale: message schemas are the contract between services, so they are reviewed on their own.
		References: UML3Views::MessageSchemaView; UML3Messaging::MessageType; SysML 7.26.2.
		*/
		expose OnlineStoreMessaging::*;
	}

	view checkoutSequence : SequenceDiagram {
		doc
		/*
		UML sequence diagram of checkout: the lifelines of CheckoutInteraction and the messages capture,
		result and publish exchanged between them.

		It exposes the interaction itself rather than its package, because a sequence diagram shows one
		interaction. SequenceDiagram adds no keyword filter, since an interaction is a native occurrence def
		without a UML3 keyword. Observed content: CheckoutInteraction.
		Rationale: it shows the order of events in checkout, payment capture first and the order
		announcement after the payment result.
		References: UML 2.5.1 Sequence diagram; UML 2.5.1 Interaction; UML3Views::SequenceDiagram;
		SysML 7.26.2.
		*/
		expose OnlineStoreMessaging::CheckoutInteraction;
	}

	view domainClassTable : ClassTable {
		doc
		/*
		Class table of the domain model: the classifiers of OnlineStoreDomain as the rows of a table, like
		the model browser of a UML tool.

		It exposes the same members as domainClassDiagram, but ClassTable keeps only classes, interfaces,
		data types and enumerations, and renders them as an element table. Observed content: 15 elements;
		the associations, the dependencies, the exception PaymentDeclined and the template Repository are
		left out, because their keywords are not in the table's filter.
		Rationale: a table lists every classifier compactly for review, without the layout of a diagram.
		References: UML3Views::ClassTable; SysML 7.26.2; SysML 7.26.4.
		*/
		expose OnlineStoreDomain::*;
	}
}
