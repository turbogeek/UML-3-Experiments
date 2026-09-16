library package UML3Views {
	doc
	/*
	 * UML3Views - UML-style diagram kinds as SysML v2 view definitions.
	 *
	 * A SysML v2 view selects model content with 'expose' and narrows it with 'filter'
	 * conditions (ViewUsage::exposedElement). Each definition below specializes a standard
	 * view (StandardViewDefinitions) and filters on UML3 keyword metadata, so a view usage
	 * only has to say WHAT to show:
	 *
	 *   view domainClasses : ClassDiagram { expose OnlineStoreDomain::*; }
	 *
	 * '@M' in a filter is true when an exposed element carries metadata of type M (or a
	 * specialization of M). Semantic keywords are metadata, so '@ClassMetadata' selects every
	 * '#classType' element.
	 */

	private import StandardViewDefinitions::*;
	private import Views::*;
	private import UML3Core::*;
	private import UML3Components::*;
	private import UML3Messaging::*;
	private import UML3Data::*;

	view def PackageDiagram :> GeneralView {
		doc /* UML package diagram: packages (use 'expose P::**' to include nested packages). */
		filter @SysML::Package;
	}

	view def ClassDiagram :> GeneralView {
		doc
		/*
		 * UML class diagram: classes, interfaces, data types, signals/exceptions, templates,
		 * enumerations, associations (incl. aggregation/composition) and dependencies.
		 * Features are shown inside their owners' nodes.
		 */
		filter @ClassMetadata or @ActiveClassMetadata or @InterfaceTypeMetadata or @DataTypeMetadata
			or @SignalMetadata or @ExceptionTypeMetadata or @Template or @SysML::EnumerationDefinition
			or @AssociationMetadata or @AggregationMetadata or @CompositionMetadata or @DependencyKind;
	}

	view def ComponentDiagram :> InterconnectionView {
		doc /* UML component diagram: components, services, subsystems, their ports and connectors. */
		filter @ComponentMetadata or @ServiceMetadata or @SubsystemMetadata or @InterfaceTypeMetadata
			or @SysML::PortDefinition or @SysML::PortUsage or @AssemblyMetadata or @DelegationMetadata
			or @SysML::ConnectionUsage;
		render asInterconnectionDiagram;
	}

	view def DeploymentDiagram :> GeneralView {
		doc /* UML deployment diagram: artifacts, nodes, devices, execution environments, deployments. */
		filter @ArtifactMetadata or @NodeMetadata or @DeviceMetadata or @ExecutionEnvironmentMetadata
			or @CommunicationPathMetadata or @DeploymentMetadata or @ManifestationMetadata;
	}

	view def EntityRelationshipDiagram :> GeneralView {
		doc /* Data model: entities, aggregate roots, value objects, relationships, tables, database views. */
		filter @EntityMetadata or @AggregateRootMetadata or @ValueObjectMetadata or @RelationshipMetadata
			or @TableMetadata or @DatabaseViewMetadata or @DatabaseMetadata or @MapsTo;
	}

	view def MessageSchemaView :> GeneralView {
		doc /* Messaging model: message types, channels (topics/queues) and brokers. */
		filter @MessageTypeMetadata or @CommandMetadata or @DomainEventMetadata or @QueryMessageMetadata
			or @ReplyMetadata or @DocumentMessageMetadata or @ChannelMetadata or @TopicMetadata
			or @QueueMetadata or @MessageBrokerMetadata;
	}

	view def SequenceDiagram :> SequenceView {
		doc /* UML sequence diagram: expose an interaction (an occurrence def with lifelines and messages). */
	}

	view def ClassTable :> GridView {
		doc /* Tabular class listing (UML model browser style). */
		filter @ClassMetadata or @InterfaceTypeMetadata or @DataTypeMetadata or @SysML::EnumerationDefinition;
		render asElementTable;
	}
}
