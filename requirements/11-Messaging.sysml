package UML3MessagingRequirements {
	doc
	/*
	MSG: requirements on modeling messaging with UML3: message schemas and kinds, channels and brokers,
	producers and consumers, delivery semantics, serialization and schema compatibility, interactions, and
	synchronous and asynchronous API contracts, including DDS messaging with IDL-defined types.

	Contents:
	- Messages: messageSchemas, messageKinds, wireSerialization, schemaCompatibility.
	- Channels and endpoints: channelsAndBrokers, endpointsAndFlows, flowConformance.
	- Delivery: deliverySemantics, idempotentHandling.
	- Interactions and contracts: messageInteractions, synchronousApiContracts, asynchronousApiContracts.
	- Middleware and patterns: ddsTopics, integrationPatterns.
	- UseCases: how integration engineers, developers and systems engineers use these capabilities.
	- Realization: the library elements that realize the done and tbc requirements.
	Import and export of IDL are LANG requirements; generation of schemas and API descriptions is GEN.
	References: docs/REQUIREMENTS-GUIDE.md; docs/DESIGN.md; docs/IDL-MAPPING.md; UML 2.5.1 Message;
	UML 2.5.1 Interaction; SysML 7.16; SysML 7.21.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;
	private import UML3Messaging::*;
	private import UML3Views::*;

	requirement <'UML3-MSG-001'> messageSchemas {
		doc
		/*
		UML3 shall provide message types whose payload is declared as attributes and which all inherit a standard
		header with message identifier, correlation identifier, causation identifier, sending time, content type and
		schema version. UML3 tooling shall warn about a message type that declares no payload.
		Verified by: tests/cameo/implied-specializations.json; tools/run_tests.py suite cameo; tests/rules/r09-message-without-payload.sysml; tools/run_tests.py suite rules-tests.
		*/
		@Rationale { text = "A common envelope makes messages traceable and correlatable across services; inheriting it from the library keeps every message consistent."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-MSG-002'> messageKinds {
		doc
		/*
		UML3 shall distinguish commands, domain events, query messages, replies and document messages as kinds of
		message type, and marking a message type with a kind shall make it specialize that kind, so that tools can
		select all messages of a kind.
		Verified by: tests/cameo/implied-specializations.json; tests/cameo/view-predictions.json; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "The kind of a message decides how many receivers it has and whether a reply is expected; mixing commands and events is a frequent design error."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-MSG-003'> channelsAndBrokers {
		doc
		/*
		UML3 shall provide publish-subscribe topics, point-to-point queues and the message brokers that host them,
		with the name of each channel and the partition count of topics.
		Verified by: examples/03-OnlineStoreMessaging.sysml; tests/cameo/view-predictions.json; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Channels decouple producers from consumers and their kind decides delivery; topics and brokers are verified in a view, but no example or test uses a queue."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-MSG-004'> endpointsAndFlows {
		doc
		/*
		UML3 shall provide producer, consumer and request-reply ports narrowed to the message types they carry, and
		shall let native flows between them be marked as publishing, subscribing, sending or handling, so that tools
		can select the flows of each role.
		Verified by: tests/cameo/implied-specializations.json; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Endpoints and roles show who emits and who consumes each message, which is the basis of event flow analysis and contract generation."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-MSG-005'> flowConformance {
		doc
		/*
		UML3 tooling shall report a message flow whose message type is not carried by the ports it connects, a
		publishing or subscribing flow that does not end at a channel, and a message type that is published but
		that no consumer subscribes to or handles.
		*/
		@Rationale { text = "Event-driven systems fail silently when nobody consumes a message or a consumer expects another type; the model is the only place where all flows can be checked together."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-MSG-006'> deliverySemantics {
		doc
		/*
		Channels and endpoints shall be able to declare their delivery guarantee (at most once, at least once or
		exactly once), ordering guarantee and partition key, retention period, maximum number of retries and
		dead-letter channel. UML3 tooling shall warn about a topic or queue that declares none of them.
		Verified by: tests/rules/r10-topic-without-qos.sysml; tools/run_tests.py suite rules-tests; examples/03-OnlineStoreMessaging.sysml; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Delivery semantics decide whether consumers must deduplicate, reorder or retry; they are design decisions and must not be left to broker defaults."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-MSG-007'> idempotentHandling {
		doc
		/*
		A consumer, handler or operation shall be markable as idempotent, meaning that handling the same message
		more than once has the same effect as handling it once.
		Verified by: examples/03-OnlineStoreMessaging.sysml; tests/cameo/display-expectations.json; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "At-least-once delivery requires idempotent handlers; the keyword label is verified, but the implied specialization is not, and in the example it is the second semantic keyword of a definition."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-MSG-008'> wireSerialization {
		doc
		/*
		A message type shall be able to declare the serialization format it uses on the wire and a reference to the
		external schema that defines its encoding.
		Verified by: examples/03-OnlineStoreMessaging.sysml; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Producers and consumers must agree on the encoding; the format loads and validates in the example, but no check or generator reads it yet."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-MSG-009'> schemaCompatibility {
		doc
		/*
		A message type shall declare its version and a compatibility mode (backward, forward, full or none), and
		UML3 tooling shall report the changes between two versions of a message type that break the declared
		compatibility, for example a removed field or a new required field.
		*/
		@Rationale { text = "Producers and consumers are deployed independently; a schema change that breaks compatibility must be found before release, not in production."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-MSG-010'> messageInteractions {
		doc
		/*
		Interactions between services, brokers and consumers shall be modeled with native SysML v2 occurrence
		definitions, lifelines, event occurrences and messages typed by UML3 message types, without UML3-specific
		interaction constructs, and shall be selectable for sequence diagrams.
		Verified by: tests/cameo/view-predictions.json; tools/run_tests.py suite cameo; tools/run_tests.py suite traceability.
		*/
		@Rationale { text = "SysML v2 already has interactions with messages; reusing them keeps scenarios consistent with the message schemas they exchange."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-MSG-011'> synchronousApiContracts {
		doc
		/*
		UML3 shall let a provided port describe a synchronous API contract: its resources or remote procedures,
		operations with HTTP method and path or procedure name, request, response and error message types, status
		codes and timeouts, complete enough to derive OpenAPI and gRPC service descriptions.
		*/
		@Rationale { text = "Most service interfaces are REST or gRPC APIs; request-reply ports and interface operations do not capture paths, methods, status codes or errors."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-MSG-012'> asynchronousApiContracts {
		doc
		/*
		UML3 shall let a service state its asynchronous contract independently of its wiring: the channels it sends
		to and receives from, the message types on each, reply channels and correlation for asynchronous
		request-reply, and protocol bindings (for example Kafka, AMQP or MQTT), complete enough to derive an
		AsyncAPI document.
		*/
		@Rationale { text = "A service publishes its event contract before anyone is wired to it; today the contract is spread over ports, flows and channel instances and has no protocol bindings."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-MSG-013'> ddsTopics {
		doc
		/*
		UML3 shall support DDS messaging: a DDS topic shall be typed by a data type defined in or imported from OMG
		IDL, the key of a topic shall be the identifier features of that type, CDR shall be a serialization format,
		and DDS quality of service policies (at least reliability, durability, history, deadline and liveliness)
		shall be declarable on topics, data writers and data readers.
		*/
		@Rationale { text = "DDS is the OMG messaging middleware for IDL-described data; UML3 imports IDL structs as data types, while message types must be item definitions, so an IDL type cannot be a topic type without a wrapper."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-MSG-014'> integrationPatterns {
		doc
		/*
		UML3 shall provide the common enterprise integration patterns as components with defined message behavior:
		at least content-based router, message filter, message translator, splitter, aggregator and claim check.
		*/
		@Rationale { text = "Integration flows are built from a small set of well-known patterns; naming them in the model makes flows understandable and generatable for integration frameworks."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	package UseCases {
		doc
		/*
		UseCases: how integration engineers, software developers and systems engineers use UML3 messaging.

		Contents:
		- DesignEventDrivenIntegration: an integration engineer designs messages, channels, flows and scenarios.
		- PublishServiceApiContracts: an integration engineer and a developer publish versioned API contracts.
		- IntegrateDdsParticipants: an integration engineer and a systems engineer exchange IDL-typed data over DDS.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def DesignEventDrivenIntegration {
			doc
			/*
			An integration engineer defines commands, events and replies with their payloads, the topics, queues and
			brokers that carry them, the producers and consumers with their delivery semantics and idempotency,
			and the interactions that show a business scenario end to end.
			*/
			subject environment : UML3Environment;
			actor integrator : IntegrationEngineer;
			objective {
				doc /* Every message has a known producer, channel, consumer and delivery guarantee, and flows are consistent. */
			}
		}

		use case def PublishServiceApiContracts {
			doc
			/*
			An integration engineer describes the synchronous and asynchronous contracts of a service with their
			serialization and versions, and a software developer implements or consumes the service from the
			published contract and learns before release whether a change breaks compatible clients.
			*/
			subject environment : UML3Environment;
			actor integrator : IntegrationEngineer;
			actor developer : SoftwareDeveloper;
			objective {
				doc /* Consumers can rely on a published, versioned contract that the model keeps complete and compatible. */
			}
		}

		use case def IntegrateDdsParticipants {
			doc
			/*
			An integration engineer and a systems engineer use IDL-defined data types as DDS topic types, declare
			their keys and quality of service policies, and connect the software participants of a system that
			exchange them.
			*/
			subject environment : UML3Environment;
			actor integrator : IntegrationEngineer;
			actor systemsEngineer : SystemsEngineer;
			objective {
				doc /* DDS participants agree on topic types, keys, encoding and quality of service from one model. */
			}
		}

		#traces dependency from DesignEventDrivenIntegration to 'UML3-MSG-001', 'UML3-MSG-002', 'UML3-MSG-003',
			'UML3-MSG-004', 'UML3-MSG-005', 'UML3-MSG-006', 'UML3-MSG-007', 'UML3-MSG-010', 'UML3-MSG-014';
		#traces dependency from PublishServiceApiContracts to 'UML3-MSG-008', 'UML3-MSG-009', 'UML3-MSG-011',
			'UML3-MSG-012', UML3SecurityRequirements::'UML3-SEC-008', UML3SecurityRequirements::'UML3-SEC-009';
		#traces dependency from IntegrateDdsParticipants to 'UML3-MSG-001', 'UML3-MSG-006', 'UML3-MSG-008',
			'UML3-MSG-013';
	}

	package Realization {
		doc
		/*
		Realization: the library elements that realize the done and tbc MSG requirements.

		Contents:
		- #realizes dependencies from UML3Messaging and UML3Views elements to MSG requirements.
		*/
		#realizes dependency from UML3Messaging::MessageTypeMetadata to 'UML3-MSG-001';
		#realizes dependency from UML3Messaging::MessageHeader to 'UML3-MSG-001';
		#realizes dependency from UML3Messaging::CommandMetadata to 'UML3-MSG-002';
		#realizes dependency from UML3Messaging::DomainEventMetadata to 'UML3-MSG-002';
		#realizes dependency from UML3Messaging::QueryMessageMetadata to 'UML3-MSG-002';
		#realizes dependency from UML3Messaging::ReplyMetadata to 'UML3-MSG-002';
		#realizes dependency from UML3Messaging::DocumentMessageMetadata to 'UML3-MSG-002';
		#realizes dependency from UML3Messaging::ChannelMetadata to 'UML3-MSG-003';
		#realizes dependency from UML3Messaging::TopicMetadata to 'UML3-MSG-003';
		#realizes dependency from UML3Messaging::QueueMetadata to 'UML3-MSG-003';
		#realizes dependency from UML3Messaging::MessageBrokerMetadata to 'UML3-MSG-003';
		#realizes dependency from UML3Messaging::ProducerPort to 'UML3-MSG-004';
		#realizes dependency from UML3Messaging::ConsumerPort to 'UML3-MSG-004';
		#realizes dependency from UML3Messaging::RequestReplyPort to 'UML3-MSG-004';
		#realizes dependency from UML3Messaging::Publishes to 'UML3-MSG-004';
		#realizes dependency from UML3Messaging::Subscribes to 'UML3-MSG-004';
		#realizes dependency from UML3Messaging::Sends to 'UML3-MSG-004';
		#realizes dependency from UML3Messaging::Handles to 'UML3-MSG-004';
		#realizes dependency from UML3Messaging::QualityOfService to 'UML3-MSG-006';
		#realizes dependency from UML3Messaging::Idempotent to 'UML3-MSG-007';
		#realizes dependency from UML3Messaging::Serialization to 'UML3-MSG-008';
		#realizes dependency from UML3Messaging::MessageType to 'UML3-MSG-010';
		#realizes dependency from UML3Views::SequenceDiagram to 'UML3-MSG-010';
	}
}
