library package UML3Messaging {
	doc
	/*
	UML3Messaging: message schemas, channels, endpoints and delivery semantics for event-driven and
	service architectures, defined as a SysML v2 model library.

	Message types are item defs: objects that flow between parts. Channels and brokers are parts, the
	runtime elements that carry the messages. Producer and consumer endpoints are ports whose directed
	items hold the messages, so native SysML flows connect them, and interactions (sequence diagrams)
	exchange the same message types with native 'message' usages:
	  #publishes flow of OrderPlaced from checkout.events.outboundMessages
	    to kafka.ordersTopic.inbound.inboundMessages;
	  message capture of CapturePayment from checkout.requestPayment to processor.receiveRequest;

	Contents:
	- Message schemas: MessageHeader, MessageType, Command, DomainEvent, QueryMessage, Reply, DocumentMessage.
	- Message keywords: #messageType, #command, #domainEvent, #queryMessage, #reply, #documentMessage.
	- Channels and brokers: Channel, Topic, Queue, MessageBroker (#channel, #topic, #queue, #broker).
	- Endpoints: ProducerPort, ConsumerPort, RequestReplyPort.
	- Delivery semantics: @Serialization, @QualityOfService, their enumerations, and #idempotent.
	- Flow roles: #publishes, #subscribes, #sends, #handles.

	Rationale: messages, channels and endpoints are ordinary items, parts and ports, so UML3 adds their
	meaning with keywords and metadata instead of a messaging-specific notation.
	References: UML 2.5.1 Signal; UML 2.5.1 InformationFlow; UML 2.5.1 Message; SysML 7.16; SysML 7.27.3.
	*/

	private import ScalarValues::*;
	private import Base::Anything;
	private import Metaobjects::SemanticMetadata;
	private import UML3Core::*;
	private import UML3Types::*;
	private import UML3Components::*;

	comment MessagingSchemaDesign about MessageHeader, MessageType, Command, DomainEvent, QueryMessage, Reply,
		DocumentMessage
		/*
		Message schemas. A message type is an item def that specializes UML3Core::Signal: an object
		that one participant sends and another receives, usable as the payload of flows, of interaction
		messages and of 'send' and 'accept' actions. Payload fields are attributes of the message type.
		Every message type inherits the header, so the envelope is the same across the model (verified
		in CATIA Magic: every #domainEvent inherits header). The kinds state the intent of a message: a
		command asks for an action, a domain event reports a fact, a query message asks for
		information, a reply answers a command or query, and a document message transfers data without
		intent. check_rules.py R09 warns when a message type declares no payload attribute.
		References: UML 2.5.1 Signal; UML 2.5.1 InformationItem; SysML 7.10; SysML 7.16; E05.
		*/

	attribute def MessageHeader {
		doc
		/*
		The message envelope: identification, correlation and format data common to all messages, kept
		apart from the payload.

		Usage: every MessageType owns 'header'; a message type binds header values by redefinition
		(see MessageType).

		Rationale: an attribute def, because the header is a value without identity that travels with
		its message. The fields are envelope attributes common to messaging platforms and standards
		(compare the CloudEvents attributes id, time and datacontenttype).
		References: UML 2.5.1 DataType; SysML 7.7.
		*/
		attribute messageId : Uuid {
			doc
			/*
			Unique identifier of this message instance, assigned by the producer. Consumers use it to
			detect duplicates, and the correlationId and causationId of other messages refer to it.
			*/
		}
		attribute correlationId : Uuid[0..1] {
			doc
			/*
			Identifier shared by all messages of one conversation, such as a request and its reply or the
			steps of a workflow. A requester matches a Reply to its request by this value; when the
			request starts the conversation, the value is usually the messageId of the request.
			*/
		}
		attribute causationId : Uuid[0..1] {
			doc
			/*
			The messageId of the message that directly caused this one, for example of the command that
			produced an event. Together with correlationId it lets tools rebuild the causal chain of a
			workflow.
			*/
		}
		attribute sentAt : Timestamp {
			doc
			/*
			The instant at which the producer sent the message, as ISO 8601 / RFC 3339 text
			(UML3Types::Timestamp).
			*/
		}
		attribute contentType : String[0..1] {
			doc
			/*
			Media type of the encoded payload, for example "application/json": the per-message
			counterpart of the @Serialization format declared on the message type.
			*/
		}
		attribute schemaVersion : String[0..1] {
			doc
			/*
			Version of the message schema that the payload conforms to, for example "1" or "2.1".
			Consumers use it to read several versions of a message type during schema evolution.
			*/
		}
	}

	abstract item def MessageType :> Signal {
		doc
		/*
		A message schema: a signal whose attributes are the payload fields and which carries a
		MessageHeader envelope.

		Usage: apply #messageType, or the keyword of a more specific kind, to an item def and declare
		the payload as attributes. Redefine 'header' to bind header values for every message of the type:
		  #domainEvent item def OrderPlaced {
		    @Serialization { format = SerializationFormat::avro; }
		    attribute orderId : Uuid;
		    attribute :>> header { attribute :>> schemaVersion = "1"; }
		  }

		Rationale: an item def, through UML3Core::Signal, because a message is an object that flows
		between parts. The keyword is #messageType because 'message' is a reserved SysML word.
		References: UML 2.5.1 Signal; UML 2.5.1 InformationItem; SysML 7.10; SysML 7.16.
		*/
		attribute header : MessageHeader {
			doc /* The envelope of the message; inherited by every message type (see MessageHeader). */
		}
	}
	abstract item messageTypes : MessageType[0..*] nonunique :> signals {
		doc /* All messages; usages marked #messageType or with a message-kind keyword subset this feature. */
	}

	abstract item def Command :> MessageType {
		doc
		/*
		A message that asks a receiver to perform an action, named in the imperative (CapturePayment).
		Exactly one logical handler processes it, and the handler may reject it.

		Usage: #command item def CapturePayment { attribute orderId : Uuid; attribute amount : Money; }
		A #sends flow carries it to a queue or directly to its handler.
		References: UML 2.5.1 Signal; UML 2.5.1 SendSignalAction.
		*/
	}
	abstract item commands : Command[0..*] nonunique :> messageTypes {
		doc /* All command messages; #command usages subset this feature. */
	}

	abstract item def DomainEvent :> MessageType {
		doc
		/*
		A message that reports a fact that has happened in the domain, named in the past tense
		(OrderPlaced). Receivers cannot reject a fact, only react to it, and an event has zero or more
		subscribers.

		Usage: #domainEvent item def OrderPlaced { attribute orderId : Uuid; attribute total : Money; }
		A #publishes flow carries it to a #topic.
		References: UML 2.5.1 Signal; UML 2.5.1 SignalEvent.
		*/
		attribute aggregateId : String[0..1] {
			doc
			/*
			Identifier of the aggregate whose change the event records (see UML3Data::AggregateRoot).
			It is often used as the partition key, so that the events of one aggregate stay in order.
			*/
		}
		attribute sequenceNumber : UInt64[0..1] {
			doc
			/*
			Position of the event in the event sequence of its aggregate or stream. Consumers use it to
			detect gaps, duplicates and out-of-order delivery.
			*/
		}
	}
	abstract item domainEvents : DomainEvent[0..*] nonunique :> messageTypes {
		doc /* All domain event messages; #domainEvent usages subset this feature. */
	}

	abstract item def QueryMessage :> MessageType {
		doc
		/*
		A message that requests information; it is answered by a Reply.

		Usage: #queryMessage item def GetOrderStatus { attribute orderId : Uuid; }

		Rationale: the name avoids a clash with #query, the UML3Core keyword for query operations
		(UML3Core::query).
		References: UML 2.5.1 Signal; UML 2.5.1 Operation.
		*/
	}
	abstract item queryMessages : QueryMessage[0..*] nonunique :> messageTypes {
		doc /* All query messages; #queryMessage usages subset this feature. */
	}

	abstract item def Reply :> MessageType {
		doc
		/*
		A message that answers a Command or a QueryMessage, for example with a result or a rejection.

		Usage: #reply item def PaymentResult { attribute orderId : Uuid; attribute approved : Boolean; }
		The requester matches the reply to its request by header.correlationId; a RequestReplyPort
		carries the request and the reply.
		References: UML 2.5.1 Signal; UML 2.5.1 Message.
		*/
	}
	abstract item replies : Reply[0..*] nonunique :> messageTypes {
		doc /* All reply messages; #reply usages subset this feature. */
	}

	abstract item def DocumentMessage :> MessageType {
		doc
		/*
		A message that transfers a data document, such as the current state of an entity, without
		implying what the receiver should do with it (state transfer).

		Usage:
		  #documentMessage item def CustomerSnapshot {
		    attribute customerId : Uuid;
		    attribute email : EmailAddress;
		  }
		References: UML 2.5.1 Signal; UML 2.5.1 InformationItem.
		*/
	}
	abstract item documentMessages : DocumentMessage[0..*] nonunique :> messageTypes {
		doc /* All document messages; #documentMessage usages subset this feature. */
	}

	comment MessagingChannelDesign about Channel, Topic, Queue, MessageBroker
		/*
		Channels and brokers. A channel is a part def: channels are runtime elements with ports, owned
		as parts of the broker that hosts them. Producers send to the inbound port of a channel and
		consumers receive from its outbound port, so a message path through a broker is two flows: a
		#publishes (or #sends) flow into the channel and a #subscribes (or #handles) flow out of it. A
		topic delivers every message to every subscriber; a queue delivers each message to one receiver.
		check_rules.py R10 warns when a #topic or #queue definition declares no @QualityOfService.
		References: SysML 7.11; SysML 7.12; SysML 7.16; UML3Components::Component.
		*/

	abstract part def Channel {
		doc
		/*
		A named conduit that transports messages from producers to consumers.

		Usage: apply #channel, or the more specific #topic or #queue, to a part def; bind the broker
		name and narrow the ports to the message types of the channel:
		  #topic part def OrderEventsTopic {
		    attribute :>> channelName = "store.orders.v1";
		    port :>> inbound : OrderEventsIn;
		    port :>> outbound : OrderEventsOut;
		  }
		References: SysML 7.11; SysML 7.12.
		*/
		attribute channelName : String[0..1] {
			doc
			/*
			The name of the channel on the broker, for example "store.orders.v1". It is kept apart from
			the model name because broker names are often not valid unquoted SysML names.
			*/
		}
		port inbound : ConsumerPort[0..1] {
			doc
			/*
			The receiving side of the channel: flows from producers end at inbound.inboundMessages.
			Redefine it with a ConsumerPort specialization to narrow the accepted message types.
			*/
		}
		port outbound : ProducerPort[0..1] {
			doc
			/*
			The delivering side of the channel: flows to consumers start at outbound.outboundMessages.
			Redefine it with a ProducerPort specialization to narrow the delivered message types.
			*/
		}
	}
	abstract part channels : Channel[0..*] nonunique {
		doc /* All channels; #channel usages, and #topic and #queue usages indirectly, subset this feature. */
	}

	abstract part def Topic :> Channel {
		doc
		/*
		A publish/subscribe channel: every subscriber receives every message published to the topic.

		Usage:
		  #topic part def OrderEventsTopic { @QualityOfService { ordering = OrderingGuarantee::perKey; } }
		Several consumers can share one subscription (for example a Kafka consumer group): each
		subscription receives every message, and the consumers of a subscription divide its messages
		among themselves.
		References: UML 2.5.1 InformationFlow; SysML 7.11.
		*/
		attribute partitionCount : Natural[0..1] {
			doc
			/*
			Number of partitions (or shards) the topic is split into. Order is kept only within a
			partition, which is why perKey ordering relies on the partitionKey of @QualityOfService.
			*/
		}
	}
	abstract part topics : Topic[0..*] nonunique :> channels {
		doc /* All topics; #topic usages subset this feature. */
	}

	abstract part def Queue :> Channel {
		doc
		/*
		A point-to-point channel: each message is consumed by exactly one receiver, even when several
		receivers compete for the messages of the queue.

		Usage:
		  #queue part def PaymentCommands { @QualityOfService { delivery = DeliveryGuarantee::atLeastOnce; } }
		With atLeastOnce delivery a message can be redelivered after a failure, so receivers should be
		#idempotent.
		References: SysML 7.11.
		*/
	}
	abstract part queues : Queue[0..*] nonunique :> channels {
		doc /* All queues; #queue usages subset this feature. */
	}

	abstract part def MessageBroker :> Component {
		doc
		/*
		Messaging middleware that hosts channels, such as a Kafka cluster, a RabbitMQ virtual host or a
		cloud service like Amazon SNS/SQS.

		Usage: the channels are parts of the broker, and @Technology names the product:
		  #broker part def KafkaCluster {
		    @Technology { technologyName = "Apache Kafka"; technologyVersion = "3.8"; }
		    part ordersTopic : OrderEventsTopic;
		  }

		Rationale: a component (UML3Components::Component), because a broker is a replaceable unit of
		the architecture with its own lifecycle.
		References: UML 2.5.1 Component; SysML 7.11; UML3Components::Technology.
		*/
	}
	abstract part messageBrokers : MessageBroker[0..*] nonunique :> components {
		doc /* All message brokers; #broker usages subset this feature. */
	}

	comment MessagingEndpointDesign about ProducerPort, ConsumerPort, RequestReplyPort
		/*
		Endpoints. A messaging endpoint is a port whose directed items hold the messages: 'out' items
		for what the owner emits and 'in' items for what it receives. A flow goes from an 'out' item to
		an 'in' item. Specializations narrow the generic MessageType by redefining the item with ':>>'
		and repeating its direction. The opposite side of a request/reply pair uses the conjugated port
		(~), which reverses the directions of all its items.
		References: UML 2.5.1 Port; SysML 7.12; SysML 7.12.3; SysML 7.16; KerML 7.3.4.5.
		*/

	abstract port def ProducerPort {
		doc
		/*
		An endpoint that emits messages.

		Usage: specialize it and redefine outboundMessages to narrow the message type:
		  port def OrderEventsOut :> ProducerPort { out item :>> outboundMessages : OrderPlaced[0..*]; }
		References: UML 2.5.1 Port; SysML 7.12.
		*/
		out item outboundMessages : MessageType[0..*] {
			doc /* The messages emitted through the port; the source of outgoing flows. */
		}
	}

	abstract port def ConsumerPort {
		doc
		/*
		An endpoint that receives messages.

		Usage: specialize it and redefine inboundMessages to narrow the message type:
		  port def OrderEventsIn :> ConsumerPort { in item :>> inboundMessages : OrderPlaced[0..*]; }
		References: UML 2.5.1 Port; SysML 7.12.
		*/
		in item inboundMessages : MessageType[0..*] {
			doc /* The messages received through the port; the target of incoming flows. */
		}
	}

	abstract port def RequestReplyPort {
		doc
		/*
		A request/reply endpoint, synchronous or asynchronous, declared from the client side: it sends
		a request and receives a Reply. The server side uses the conjugated port, ~RequestReplyPort or
		the conjugate of a specialization.

		Usage:
		  port def PaymentClientPort :> RequestReplyPort {
		    out item :>> request : CapturePayment[0..1];
		    in item :>> response : PaymentResult[0..1];
		  }
		  #service part def PaymentProcessor { port payments : ~PaymentClientPort; }

		Rationale: SysML v2 has no call event, so a call between parts is modeled as a request and a
		reply exchanged through this port.
		References: UML 2.5.1 CallEvent; UML 2.5.1 Port; SysML 7.12.3.
		*/
		out item request : MessageType[0..1] {
			doc
			/*
			The request that the client sends, usually a Command or a QueryMessage; narrow it by
			redefinition.
			*/
		}
		in item response : Reply[0..1] {
			doc /* The Reply that the client receives for its request; narrow it by redefinition. */
		}
	}

	comment MessagingDeliveryDesign about SerializationFormat, DeliveryGuarantee, OrderingGuarantee,
		Serialization, QualityOfService, idempotentElements, idempotent
		/*
		Delivery semantics. Encoding and quality of service are configuration values, so they are plain
		metadata with attributes (@Serialization, @QualityOfService) whose value sets are enumerations.
		Plain metadata does not appear in the keyword labels of CATIA Magic diagrams. #idempotent is a
		marker without values, so it is a semantic keyword like the UML3Core markers: it shows as a
		label, and marked usages form a queryable set. Duplicate delivery (atLeastOnce) is safe only for
		idempotent consumers.
		References: KerML 7.4.13; SysML 7.8; SysML 7.27; SysML 7.27.3; E01.
		*/

	enum def SerializationFormat {
		doc /* The wire encoding of a message type; the value of @Serialization format. */
		enum json {
			doc /* JSON text (RFC 8259), usually described by a JSON Schema. */
		}
		enum avro {
			doc /* Apache Avro binary encoding, written and read with an Avro schema. */
		}
		enum protobuf {
			doc /* Protocol Buffers binary encoding, defined by a .proto schema. */
		}
		enum xmlFormat {
			doc /* XML text, usually described by an XML Schema (XSD). */
		}
		enum cbor {
			doc
			/*
			CBOR (Concise Binary Object Representation, RFC 8949): a binary encoding whose data model
			extends that of JSON.
			*/
		}
		enum messagePack {
			doc /* MessagePack: a compact binary encoding of JSON-like data. */
		}
	}

	enum def DeliveryGuarantee {
		doc
		/*
		How often a message reaches a consumer when failures occur; the value of @QualityOfService
		delivery.
		*/
		enum atMostOnce {
			doc /* Each message is delivered once or not at all: it can be lost but is never duplicated. */
		}
		enum atLeastOnce {
			doc /* Each message is redelivered until acknowledged: it is not lost but can be duplicated. */
		}
		enum exactlyOnce {
			doc
			/*
			Each message takes effect exactly once. A broker can provide it within its own processing (for
			example Kafka transactions); end to end it needs at-least-once delivery with idempotent or
			transactional consumers.
			*/
		}
	}

	enum def OrderingGuarantee {
		doc
		/*
		The order in which consumers receive the messages of a channel; the value of @QualityOfService
		ordering.
		*/
		enum unordered {
			doc /* No order is guaranteed. */
		}
		enum perKey {
			doc /* Messages with the same partitionKey value arrive in the order they were sent. */
		}
		enum total {
			doc
			/*
			All messages of the channel arrive in the order they were sent; this usually limits the
			channel to one partition or one consumer.
			*/
		}
	}

	metadata def Serialization {
		doc
		/*
		How a message type is encoded on the wire, and where its schema is.

		Usage: in the body of the message type:
		  @Serialization { format = SerializationFormat::avro; schemaRef = "schemas/order-placed-v1.avsc"; }
		References: KerML 7.4.13; SysML 7.27.
		*/
		attribute format : SerializationFormat {
			doc /* The encoding of the message: one of the SerializationFormat literals; required. */
		}
		attribute schemaRef : String[0..1] {
			doc
			/*
			Optional reference to the schema of the encoded form: a file path, a URL or a schema-registry
			subject.
			*/
		}
	}

	metadata def QualityOfService {
		doc
		/*
		Delivery semantics of a channel or an endpoint: delivery and ordering guarantees, partitioning,
		retention, retries and dead-lettering. Every attribute is optional; an absent value is unspecified.

		Usage:
		  #topic part def OrderEventsTopic {
		    @QualityOfService {
		      delivery = DeliveryGuarantee::atLeastOnce; ordering = OrderingGuarantee::perKey;
		      partitionKey = "orderId"; retentionPeriod = "P7D"; deadLetterChannel = "store.orders.v1.dlq";
		    }
		  }
		check_rules.py R10 warns when a #topic or #queue definition has no @QualityOfService.
		References: KerML 7.4.13; SysML 7.27.
		*/
		attribute delivery : DeliveryGuarantee[0..1] {
			doc /* The delivery guarantee: atMostOnce, atLeastOnce or exactlyOnce. */
		}
		attribute ordering : OrderingGuarantee[0..1] {
			doc /* The ordering guarantee: unordered, perKey (by partitionKey) or total. */
		}
		attribute partitionKey : String[0..1] {
			doc
			/*
			Name of the message attribute whose value selects the partition, for example "orderId".
			Messages with the same key go to the same partition, which perKey ordering relies on.
			*/
		}
		attribute retentionPeriod : DurationValue[0..1] {
			doc /* How long the channel keeps messages, as an ISO 8601 duration such as "P7D" (seven days). */
		}
		attribute maxRetries : Natural[0..1] {
			doc
			/*
			How many times a failed delivery or handling is retried before the message is given up; it
			is then moved to the deadLetterChannel, if one is set.
			*/
		}
		attribute deadLetterChannel : String[0..1] {
			doc
			/*
			The channelName of the dead-letter channel that receives messages that cannot be delivered
			or handled, for example "store.orders.v1.dlq".
			*/
		}
	}

	abstract ref idempotentElements : Anything[0..*] nonunique {
		doc /* All usages marked #idempotent. On a definition the keyword is a label only (see idempotent). */
	}

	metadata def <idempotent> idem :> SemanticMetadata {
		doc
		/*
		Keyword #idempotent: handling the same message more than once has the same effect as handling
		it once.

		Usage: on a consumer, a handler action or an operation, for example '@idempotent;' in the body
		of #service part def FulfillmentService. Consumers of atLeastOnce channels receive duplicates,
		so they should be idempotent; discarding messages whose header.messageId was already handled
		is one way. On a definition the implied specialization is to Base::Anything, which adds
		nothing, so only marked usages join idempotentElements.
		References: KerML 7.4.13; SysML 7.27.3; E01.
		*/
		:>> baseType = idempotentElements meta SysML::Usage;
	}

	comment MessagingKeywordDesign about messageType, command, domainEvent,
		queryMessage, reply, documentMessage, channel, topic,
		queue, broker
		/*
		Semantic keywords for messaging, built like those of UML3Core: each specializes SemanticMetadata
		and binds baseType to a library collection usage. A keyworded definition specializes the library
		definition (a #domainEvent item def is a DomainEvent, a MessageType and a UML3Core::Signal,
		verified in CATIA Magic) and a keyworded usage subsets the collection. Message keywords apply to
		items and channel keywords to parts. Names avoid reserved words and clashes: #messageType
		('message' is reserved), #queryMessage (#query is the UML3Core query operation) and #broker for
		MessageBroker. UML3Views::MessageSchemaView selects elements by these keywords.
		References: KerML 7.4.13; KerML 9.2.16; SysML 7.27.3.
		*/

	metadata def <messageType> msg :> SemanticMetadata {
		doc
		/*
		Keyword #messageType: the item is a UML3 MessageType (a definition specializes MessageType, a
		usage subsets messageTypes).
		*/
		:>> baseType = messageTypes meta SysML::Usage;
	}
	metadata def <command> cmd :> SemanticMetadata {
		doc /* Keyword #command: the item is a Command, a request for one handler to act. */
		:>> baseType = commands meta SysML::Usage;
	}
	metadata def <domainEvent> evt :> SemanticMetadata {
		doc /* Keyword #domainEvent: the item is a DomainEvent, a fact that has happened. */
		:>> baseType = domainEvents meta SysML::Usage;
	}
	metadata def <queryMessage> qmsg :> SemanticMetadata {
		doc /* Keyword #queryMessage: the item is a QueryMessage, a request for information. */
		:>> baseType = queryMessages meta SysML::Usage;
	}
	metadata def <reply> ReplyMetadata :> SemanticMetadata {
		doc /* Keyword #reply: the item is a Reply to a command or query message. */
		:>> baseType = replies meta SysML::Usage;
	}
	metadata def <documentMessage> docMsg :> SemanticMetadata {
		doc /* Keyword #documentMessage: the item is a DocumentMessage, data transferred without intent. */
		:>> baseType = documentMessages meta SysML::Usage;
	}
	metadata def <channel> chan :> SemanticMetadata {
		doc /* Keyword #channel: the part is a UML3 Channel. */
		:>> baseType = channels meta SysML::Usage;
	}
	metadata def <topic> TopicMetadata :> SemanticMetadata {
		doc /* Keyword #topic: the part is a publish/subscribe Topic. */
		:>> baseType = topics meta SysML::Usage;
	}
	metadata def <queue> QueueMetadata :> SemanticMetadata {
		doc /* Keyword #queue: the part is a point-to-point Queue. */
		:>> baseType = queues meta SysML::Usage;
	}
	metadata def <broker> brk :> SemanticMetadata {
		doc /* Keyword #broker: the part is a MessageBroker that hosts channels. */
		:>> baseType = messageBrokers meta SysML::Usage;
	}

	comment MessagingFlowRoleDesign about publishingFlows, subscribingFlows, sendingFlows, handlingFlows,
		publishes, subscribes, sends, handles
		/*
		Flow role keywords: they state the role a flow plays in the messaging design, which the flow
		itself does not show. A flow usage is a connector, and so a feature and a type, so semantic
		metadata applies to it. As for the UML3Core markers, the baseType is a reference usage typed by
		Base::Anything, so the keywords are valid on flows, messages and connections; a marked flow
		subsets the role set (verified in CATIA Magic for all four roles). Publish/subscribe: #publishes
		into a channel, #subscribes out of it. Point-to-point and request/reply: #sends on the sender's
		side, #handles on the handler's side.
		References: UML 2.5.1 InformationFlow; KerML 7.4.6; KerML 7.4.13; SysML 7.16; E01.
		*/

	abstract ref publishingFlows : Anything[0..*] nonunique {
		doc /* All flows marked #publishes. */
	}
	abstract ref subscribingFlows : Anything[0..*] nonunique {
		doc /* All flows marked #subscribes. */
	}
	abstract ref sendingFlows : Anything[0..*] nonunique {
		doc /* All flows marked #sends. */
	}
	abstract ref handlingFlows : Anything[0..*] nonunique {
		doc /* All flows marked #handles. */
	}

	metadata def <publishes> pub :> SemanticMetadata {
		doc
		/*
		Keyword #publishes: the flow carries messages from a producer into a channel, usually a #topic.

		Usage:
		  #publishes flow publishOrderPlaced of OrderPlaced from checkout.events.outboundMessages
		    to kafka.ordersTopic.inbound.inboundMessages;
		References: UML 2.5.1 InformationFlow; SysML 7.16.
		*/
		:>> baseType = publishingFlows meta SysML::Usage;
	}
	metadata def <subscribes> sbs :> SemanticMetadata {
		doc
		/*
		Keyword #subscribes: the flow carries messages from a channel, usually a #topic, to a consumer
		that subscribed to it.

		Usage:
		  #subscribes flow consumeOrderPlaced of OrderPlaced from kafka.ordersTopic.outbound.outboundMessages
		    to fulfillment.events.inboundMessages;
		References: UML 2.5.1 InformationFlow; SysML 7.16.
		*/
		:>> baseType = subscribingFlows meta SysML::Usage;
	}
	metadata def <sends> Sends :> SemanticMetadata {
		doc
		/*
		Keyword #sends: the flow carries a command, query or request from its sender to a #queue or
		directly to its handler (point-to-point or request/reply).

		Usage:
		  #sends flow sendCapturePayment of CapturePayment from checkout.payments.request
		    to paymentProcessor.payments.request;
		References: UML 2.5.1 InformationFlow; UML 2.5.1 SendSignalAction; SysML 7.16.
		*/
		:>> baseType = sendingFlows meta SysML::Usage;
	}
	metadata def <handles> hdl :> SemanticMetadata {
		doc
		/*
		Keyword #handles: the flow is on the handler's side of a point-to-point or request/reply
		exchange: it delivers a sent message from a queue to its handler, or returns the handler's Reply
		to the requester.

		Usage, the reply of a request/reply exchange:
		  #handles flow returnPaymentResult of PaymentResult from paymentProcessor.payments.response
		    to checkout.payments.response;
		References: UML 2.5.1 InformationFlow; SysML 7.16.
		*/
		:>> baseType = handlingFlows meta SysML::Usage;
	}
}
