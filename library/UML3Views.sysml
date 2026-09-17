library package UML3Views {
	doc
	/*
	UML3Views: the UML diagram kinds of UML3, defined as SysML v2 view definitions.

	A SysML v2 view usage selects model content with 'expose' and keeps the exposed elements that meet
	all filter conditions of the usage and of its definition (ViewUsage::exposedElement). Each definition
	below specializes a standard view and filters on UML3 keyword metadata, so a view usage only has to
	say what part of the model to show:
	  view domainClassDiagram : ClassDiagram { expose OnlineStoreDomain::*; }
	'@M' in a filter is true when an exposed element carries metadata of type M (or a specialization of
	M). Semantic keywords are metadata, so '@ClassMetadata' selects every '#classType' element, and the
	metaclass of an element counts as metadata too, so '@SysML::PortUsage' selects port usages.
	Every definition also filters out library elements, which 'expose' would otherwise show (E06).
	Activity and state machine diagrams need no UML3 definition: use the standard ActionFlowView and
	StateTransitionView.

	Compact and detail views: the class, deployment, data and message views come in two forms. The compact
	form (ClassDiagram, DeploymentDiagram, EntityRelationshipDiagram, MessageSchemaView, PackageDiagram)
	renders as a tree diagram: one box per element with its name and keyword label. The detail form
	(ClassDetailDiagram, DeploymentDetailDiagram, EntityRelationshipDetailDiagram, MessageSchemaDetailView)
	has no rendering, so a tool shows each element with its compartments: documentation, attributes,
	items and ends.

	Status: CATIA Magic evaluates these views, and all 9 views of examples/05-OnlineStoreViews.sysml
	match their predicted includes and excludes. The test harness opens each view as a diagram, lays it
	out and exports it to SVG, and checks the drawn names and that no shapes overlap (E13, E14).

	Rationale: a SysML v2 view definition is an ordinary model element, so the UML diagram kinds are part
	of the model library, and specializing the standard views keeps their standard rendering.

	Contents:
	- Structure diagrams: PackageDiagram, ClassDiagram, ClassDetailDiagram, ComponentDiagram,
	  DeploymentDiagram, DeploymentDetailDiagram.
	- Data and messaging views: EntityRelationshipDiagram, EntityRelationshipDetailDiagram, MessageSchemaView,
	  MessageSchemaDetailView.
	- Interaction diagrams: SequenceDiagram.
	- Tables: ClassTable.
	References: SysML 7.26; SysML 7.5.4; SysML 9.2.20; KerML 8.4.4.14; E06; E07; E13; E14; docs/DESIGN.md.
	*/

	private import StandardViewDefinitions::*;
	private import Views::*;
	private import UML3Core::*;
	private import UML3Components::*;
	private import UML3Messaging::*;
	private import UML3Data::*;

	comment LibraryElementFilterDesign about PackageDiagram, ClassDiagram, ClassDetailDiagram, ComponentDiagram,
		DeploymentDiagram, DeploymentDetailDiagram, EntityRelationshipDiagram, EntityRelationshipDetailDiagram,
		MessageSchemaView, MessageSchemaDetailView, SequenceDiagram, ClassTable
		/*
		Library element filter. Every view definition starts with
		  filter not (as KerML::Element).isLibraryElement;
		An expose is an import that ignores visibility (isImportAll), so exposing a package also exposes
		everything that package imports, even privately. Without the filter, library elements such as
		UML3Core::AggregationKind and the library port and connection bases appeared in the views.
		isLibraryElement is true for every element owned, directly or indirectly, by a library package.
		Imported user elements, such as the domain interfaces in a component view, remain by design.
		All E06 predictions held in CATIA Magic, including the two made at low confidence.
		By the same rule, the elements of a user model declared as a library package are hidden too.
		References: SysML 7.26.2; SysML 8.3.26.2; KerML 8.3.2.1.2; KerML 8.3.4.13.3; E06.
		*/

	comment CompactAndDetailViewDesign about ClassDiagram, ClassDetailDiagram, DeploymentDiagram, DeploymentDetailDiagram,
		EntityRelationshipDiagram, EntityRelationshipDetailDiagram, MessageSchemaView, MessageSchemaDetailView,
		PackageDiagram
		/*
		Compact and detail views. A view's rendering decides how a tool draws the selected elements. With
		'render asTreeDiagram', CATIA Magic draws compact boxes (name, keyword label, enumeration literals,
		metadata values); without a rendering it draws every compartment, including documentation, which
		then dominates the diagram (E14). UML3 therefore offers both: the compact definition for overviews
		and the detail definition for reviewing contents. Each pair has the same filters, written out in
		both definitions rather than inherited, so the selection does not depend on filter inheritance.
		The rendering does not position the shapes; tools lay the diagram out (E14).
		References: SysML 7.26.2; SysML 9.2.20; E13; E14.
		*/

	view def PackageDiagram :> GeneralView {
		doc
		/*
		UML package diagram: the packages among the exposed elements.

		Usage: view storePackages : PackageDiagram { expose OnlineStoreDatabase::*; }
		Use 'expose P::**' to include nested packages. Package imports and dependencies are not selected.
		It renders as a tree diagram: one compact box per package.
		The first filter hides library elements that 'expose' brings in through imports (E06).
		References: UML 2.5.1 Package diagram; SysML 7.26.2; SysML 9.2.20; E14.
		*/
		filter not (as KerML::Element).isLibraryElement;
		filter @SysML::Package;
		render asTreeDiagram;
	}

	view def ClassDiagram :> GeneralView {
		doc
		/*
		UML class diagram: classes, interfaces, data types, signals and exceptions, templates, enumerations,
		associations (including aggregations and compositions) and dependencies.

		Usage: view domainClassDiagram : ClassDiagram { expose OnlineStoreDomain::*; }
		The filter selects elements marked #classType, #activeClass, #interfaceType, #dataType, #signal,
		#exceptionType, #template, #association, #aggregation, #composition or a dependency keyword
		(#uses, #realizes...), and every enum def. Features are not selected.
		Compact form: it renders as a tree diagram, one box per element with its name and keyword label. Use
		ClassDetailDiagram to show attributes, operations and documentation in compartments.
		The first filter hides library elements that 'expose' brings in through imports (E06).
		References: UML 2.5.1 Class diagram; SysML 7.26.2; SysML 9.2.20; E14.
		*/
		filter not (as KerML::Element).isLibraryElement;
		filter @ClassMetadata or @ActiveClassMetadata or @InterfaceTypeMetadata or @DataTypeMetadata
			or @SignalMetadata or @ExceptionTypeMetadata or @Template or @SysML::EnumerationDefinition
			or @AssociationMetadata or @AggregationMetadata or @CompositionMetadata or @DependencyKind;
		render asTreeDiagram;
	}

	view def ClassDetailDiagram :> GeneralView {
		doc
		/*
		UML class diagram, detail form: the same elements as ClassDiagram, each drawn with its compartments
		(documentation, attributes, operations, items, ends).

		Usage: view domainClassDetails : ClassDetailDiagram { expose OnlineStoreDomain::*; }
		It declares no rendering, so tools draw the full compartments; diagrams are larger than ClassDiagram.
		The filters are those of ClassDiagram, repeated rather than inherited.
		References: UML 2.5.1 Class diagram; SysML 7.26.2; SysML 7.26.5; E14.
		*/
		filter not (as KerML::Element).isLibraryElement;
		filter @ClassMetadata or @ActiveClassMetadata or @InterfaceTypeMetadata or @DataTypeMetadata
			or @SignalMetadata or @ExceptionTypeMetadata or @Template or @SysML::EnumerationDefinition
			or @AssociationMetadata or @AggregationMetadata or @CompositionMetadata or @DependencyKind;
	}

	view def ComponentDiagram :> InterconnectionView {
		doc
		/*
		UML component diagram (and composite structure diagram): components, services, subsystems, their
		ports, the interfaces they provide or require, and connectors.

		Usage: view architectureComponents : ComponentDiagram { expose OnlineStoreArchitecture::*; }
		The filter selects elements marked #component, #service, #subsystem, #interfaceType, #assembly or
		#delegation, every port def and port usage, and every connection usage. Interface and allocation
		usages are connection usages too, so exposed #deploy and #manifest allocations are selected as well.
		It renders as an interconnection diagram: parts as nested nodes with their ports on the boundary,
		connections as edges.
		The first filter hides library elements that 'expose' brings in through imports (E06).
		Rationale: an InterconnectionView, the standard view for ports and connections between parts.
		References: UML 2.5.1 Component diagram; SysML 7.26.2; SysML 9.2.19; SysML 9.2.20.
		*/
		filter not (as KerML::Element).isLibraryElement;
		filter @ComponentMetadata or @ServiceMetadata or @SubsystemMetadata or @InterfaceTypeMetadata
			or @SysML::PortDefinition or @SysML::PortUsage or @AssemblyMetadata or @DelegationMetadata
			or @SysML::ConnectionUsage;
		render asInterconnectionDiagram;
	}

	view def DeploymentDiagram :> GeneralView {
		doc
		/*
		UML deployment diagram: artifacts, nodes, devices, execution environments, communication paths,
		deployments and manifestations.

		Usage: view deploymentDiagram : DeploymentDiagram { expose OnlineStoreArchitecture::*; }
		The filter selects elements marked #artifact, #node, #device, #executionEnvironment,
		#communicationPath, #deploy or #manifest. Only exposed elements are filtered: allocations nested in
		a part, such as a cluster, are selected only with a recursive 'expose P::**'.
		Compact form: it renders as a tree diagram. Use DeploymentDetailDiagram to show compartments.
		The first filter hides library elements that 'expose' brings in through imports (E06).
		References: UML 2.5.1 Deployment diagram; SysML 7.26.2; SysML 9.2.20; E14.
		*/
		filter not (as KerML::Element).isLibraryElement;
		filter @ArtifactMetadata or @NodeMetadata or @DeviceMetadata or @ExecutionEnvironmentMetadata
			or @CommunicationPathMetadata or @DeploymentMetadata or @ManifestationMetadata;
		render asTreeDiagram;
	}

	view def DeploymentDetailDiagram :> GeneralView {
		doc
		/*
		UML deployment diagram, detail form: the same elements as DeploymentDiagram, each drawn with its
		compartments (documentation, attributes, nested parts).

		Usage: view deploymentDetails : DeploymentDetailDiagram { expose OnlineStoreArchitecture::*; }
		It declares no rendering; the filters are those of DeploymentDiagram, repeated rather than inherited.
		References: UML 2.5.1 Deployment diagram; SysML 7.26.2; E14.
		*/
		filter not (as KerML::Element).isLibraryElement;
		filter @ArtifactMetadata or @NodeMetadata or @DeviceMetadata or @ExecutionEnvironmentMetadata
			or @CommunicationPathMetadata or @DeploymentMetadata or @ManifestationMetadata;
	}

	view def EntityRelationshipDiagram :> GeneralView {
		doc
		/*
		Data model diagram: entities, aggregate roots, value objects and relationships (logical model),
		databases, tables and database views (physical model), and the #mapsTo links between the two.

		Usage: view logicalDataModel : EntityRelationshipDiagram { expose OnlineStoreDatabase::Logical::*; }
		Not a UML 2.5.1 diagram kind: UML draws data models as class diagrams. The filter selects elements
		marked #entity, #aggregateRoot, #valueObject, #relationship, #table, #dbView, #database or #mapsTo;
		columns are features of their tables and are not selected.
		Compact form: it renders as a tree diagram. Use EntityRelationshipDetailDiagram to show attributes,
		columns and keys in compartments.
		The first filter hides library elements that 'expose' brings in through imports (E06).
		References: UML3Data::Entity; UML3Data::Table; UML 2.5.1 Class diagram; SysML 7.26.2; E14.
		*/
		filter not (as KerML::Element).isLibraryElement;
		filter @EntityMetadata or @AggregateRootMetadata or @ValueObjectMetadata or @RelationshipMetadata
			or @TableMetadata or @DatabaseViewMetadata or @DatabaseMetadata or @MapsTo;
		render asTreeDiagram;
	}

	view def EntityRelationshipDetailDiagram :> GeneralView {
		doc
		/*
		Data model diagram, detail form: the same elements as EntityRelationshipDiagram, each drawn with its
		compartments (documentation, attributes or columns with their keys, relationship ends).

		Usage: view logicalDataModelDetails : EntityRelationshipDetailDiagram { expose OnlineStoreDatabase::Logical::*; }
		It declares no rendering; the filters are those of EntityRelationshipDiagram, repeated rather than
		inherited.
		References: UML3Data::Entity; UML3Data::Table; SysML 7.26.2; E14.
		*/
		filter not (as KerML::Element).isLibraryElement;
		filter @EntityMetadata or @AggregateRootMetadata or @ValueObjectMetadata or @RelationshipMetadata
			or @TableMetadata or @DatabaseViewMetadata or @DatabaseMetadata or @MapsTo;
	}

	view def MessageSchemaView :> GeneralView {
		doc
		/*
		Messaging model: message types (commands, domain events, query messages, replies, documents),
		channels (topics and queues) and brokers.

		Usage: view messageSchemas : MessageSchemaView { expose OnlineStoreMessaging::*; }
		Not a UML 2.5.1 diagram kind: in UML, message types are signals shown on class diagrams. The filter
		selects elements marked #messageType, #command, #domainEvent, #queryMessage, #reply,
		#documentMessage, #channel, #topic, #queue or #broker. Endpoint ports and the #publishes,
		#subscribes, #sends and #handles flows are not selected.
		Compact form: it renders as a tree diagram. Use MessageSchemaDetailView to show payload attributes
		and headers in compartments.
		The first filter hides library elements that 'expose' brings in through imports (E06).
		References: UML3Messaging::MessageType; UML3Messaging::Channel; UML 2.5.1 Signal; SysML 7.26.2; E14.
		*/
		filter not (as KerML::Element).isLibraryElement;
		filter @MessageTypeMetadata or @CommandMetadata or @DomainEventMetadata or @QueryMessageMetadata
			or @ReplyMetadata or @DocumentMessageMetadata or @ChannelMetadata or @TopicMetadata
			or @QueueMetadata or @MessageBrokerMetadata;
		render asTreeDiagram;
	}

	view def MessageSchemaDetailView :> GeneralView {
		doc
		/*
		Messaging model, detail form: the same elements as MessageSchemaView, each drawn with its compartments
		(documentation, payload attributes, header, quality of service values).

		Usage: view messageSchemaDetails : MessageSchemaDetailView { expose OnlineStoreMessaging::*; }
		It declares no rendering; the filters are those of MessageSchemaView, repeated rather than inherited.
		References: UML3Messaging::MessageType; SysML 7.26.2; E14.
		*/
		filter not (as KerML::Element).isLibraryElement;
		filter @MessageTypeMetadata or @CommandMetadata or @DomainEventMetadata or @QueryMessageMetadata
			or @ReplyMetadata or @DocumentMessageMetadata or @ChannelMetadata or @TopicMetadata
			or @QueueMetadata or @MessageBrokerMetadata;
	}

	view def SequenceDiagram :> SequenceView {
		doc
		/*
		UML sequence diagram: the lifelines, event occurrences and messages of an interaction.

		Usage: expose the interaction itself, an occurrence def whose parts are the lifelines:
		  view checkoutSequence : SequenceDiagram { expose OnlineStoreMessaging::CheckoutInteraction; }
		There is no keyword filter, because interactions are native SysML v2 occurrences; the SequenceView
		presents the event occurrences on the lifelines of the exposed interaction in time order.
		The first filter hides library elements that 'expose' brings in through imports (E06).
		References: UML 2.5.1 Sequence diagram; UML 2.5.1 Interaction; SysML 7.16; SysML 9.2.20.
		*/
		filter not (as KerML::Element).isLibraryElement;
	}

	view def ClassTable :> GridView {
		doc
		/*
		Tabular class listing: one row for each class, interface, data type and enumeration.

		Usage: view domainClassTable : ClassTable { expose OnlineStoreDomain::*; }
		The filter selects elements marked #classType, #interfaceType or #dataType, and every enum def;
		signals, exceptions and active classes have their own keywords and are not selected. It renders as
		an element table (Views::asElementTable). Not a UML 2.5.1 diagram kind: it lists the classifiers of
		a class diagram.
		The first filter hides library elements that 'expose' brings in through imports (E06).
		References: UML 2.5.1 Class diagram; SysML 9.2.19; SysML 9.2.20.
		*/
		filter not (as KerML::Element).isLibraryElement;
		filter @ClassMetadata or @InterfaceTypeMetadata or @DataTypeMetadata or @SysML::EnumerationDefinition;
		render asElementTable;
	}
}
