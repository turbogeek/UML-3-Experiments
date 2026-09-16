library package UML3Messaging {
	doc
	/*
	 * UML3Messaging - message schemas, channels, publish/subscribe and
	 * request/reply contracts for event-driven and service architectures.
	 *
	 * Message TYPES are item defs (they flow between parts). Channel INSTANCES are
	 * parts. Producer/consumer endpoints are ports whose directed items carry the
	 * messages, so the native SysML 'flow' / 'message' constructs and interaction
	 * (sequence) models work unchanged:
	 *   flow of OrderPlaced from orders.publisher.outbound to broker.ordersTopic.inbound;
	 */

	private import ScalarValues::*;
	private import Metaobjects::SemanticMetadata;
	private import UML3Core::*;
	private import UML3Types::*;
	private import UML3Components::*;

	/* ---------------------------------------------------------------------
	 * Message schemas
	 * --------------------------------------------------------------------- */

	attribute def MessageHeader {
		doc /* Envelope metadata common to all messages. */
		attribute messageId : Uuid;
		attribute correlationId : Uuid[0..1];
		attribute causationId : Uuid[0..1];
		attribute sentAt : Timestamp;
		attribute contentType : String[0..1];
		attribute schemaVersion : String[0..1];
	}

	abstract item def MessageType :> Signal {
		doc
		/*
		 * A message schema. Declare payload fields as attributes. Every message
		 * carries a header; override defaults with ':>> header { ... }'.
		 */
		attribute header : MessageHeader;
	}
	abstract item messageTypes : MessageType[0..*] nonunique :> signals;

	abstract item def Command :> MessageType {
		doc /* Imperative request to do something; exactly one logical handler. */
	}
	abstract item commands : Command[0..*] nonunique :> messageTypes;

	abstract item def DomainEvent :> MessageType {
		doc /* Fact that something happened (past tense); zero or more subscribers. */
		attribute aggregateId : String[0..1];
		attribute sequenceNumber : UInt64[0..1];
	}
	abstract item domainEvents : DomainEvent[0..*] nonunique :> messageTypes;

	abstract item def QueryMessage :> MessageType {
		doc /* Request for information; answered by a Reply. */
	}
	abstract item queryMessages : QueryMessage[0..*] nonunique :> messageTypes;

	abstract item def Reply :> MessageType {
		doc /* Response to a Command or QueryMessage; correlate via header.correlationId. */
	}
	abstract item replies : Reply[0..*] nonunique :> messageTypes;

	abstract item def DocumentMessage :> MessageType {
		doc /* Transfers a data document (state transfer) without implying intent. */
	}
	abstract item documentMessages : DocumentMessage[0..*] nonunique :> messageTypes;

	/* ---------------------------------------------------------------------
	 * Channels and brokers
	 * --------------------------------------------------------------------- */

	abstract part def Channel {
		doc /* A named conduit that transports messages between endpoints. */
		attribute channelName : String[0..1];
		port inbound : ConsumerPort[0..1];
		port outbound : ProducerPort[0..1];
	}
	abstract part channels : Channel[0..*] nonunique;

	abstract part def Topic :> Channel {
		doc /* Publish/subscribe channel: every subscriber receives every message. */
		attribute partitionCount : Natural[0..1];
	}
	abstract part topics : Topic[0..*] nonunique :> channels;

	abstract part def Queue :> Channel {
		doc /* Point-to-point channel: each message is consumed by exactly one receiver. */
	}
	abstract part queues : Queue[0..*] nonunique :> channels;

	abstract part def MessageBroker :> Component {
		doc /* Middleware hosting channels (Kafka cluster, RabbitMQ vhost, SNS/SQS, ...). */
	}
	abstract part messageBrokers : MessageBroker[0..*] nonunique :> components;

	/* ---------------------------------------------------------------------
	 * Endpoints
	 * --------------------------------------------------------------------- */

	abstract port def ProducerPort {
		doc /* Emits messages. Narrow the message type with ':>> outboundMessages : OrderPlaced'. */
		abstract out item outboundMessages : MessageType[0..*];
	}

	abstract port def ConsumerPort {
		doc /* Receives messages. Narrow the message type with ':>> inboundMessages : OrderPlaced'. */
		abstract in item inboundMessages : MessageType[0..*];
	}

	abstract port def RequestReplyPort {
		doc /* Synchronous or async request/reply endpoint (client side; server side is ~RequestReplyPort). */
		abstract out item request : MessageType[0..1];
		abstract in item response : Reply[0..1];
	}

	/* ---------------------------------------------------------------------
	 * Quality-of-service and serialization metadata
	 * --------------------------------------------------------------------- */

	enum def SerializationFormat {
		enum json;
		enum avro;
		enum protobuf;
		enum xmlFormat;
		enum cbor;
		enum messagePack;
	}

	enum def DeliveryGuarantee {
		enum atMostOnce;
		enum atLeastOnce;
		enum exactlyOnce;
	}

	enum def OrderingGuarantee {
		enum unordered;
		enum perKey;
		enum total;
	}

	metadata def Serialization {
		doc /* How a message type is encoded on the wire. */
		attribute format : SerializationFormat;
		attribute schemaRef : String[0..1];
	}

	metadata def QualityOfService {
		doc /* Delivery semantics of a channel or endpoint. */
		attribute delivery : DeliveryGuarantee[0..1];
		attribute ordering : OrderingGuarantee[0..1];
		attribute partitionKey : String[0..1];
		attribute retentionPeriod : DurationValue[0..1];
		attribute maxRetries : Natural[0..1];
		attribute deadLetterChannel : String[0..1];
	}

	metadata def <idempotent> Idempotent {
		doc /* Handling the same message more than once has the same effect as handling it once. */
	}

	/* ---------------------------------------------------------------------
	 * Semantic keywords
	 * --------------------------------------------------------------------- */

	metadata def <messageType> MessageTypeMetadata :> SemanticMetadata {
		:>> baseType = messageTypes meta SysML::Usage;
	}
	metadata def <command> CommandMetadata :> SemanticMetadata {
		:>> baseType = commands meta SysML::Usage;
	}
	metadata def <domainEvent> DomainEventMetadata :> SemanticMetadata {
		:>> baseType = domainEvents meta SysML::Usage;
	}
	metadata def <queryMessage> QueryMessageMetadata :> SemanticMetadata {
		:>> baseType = queryMessages meta SysML::Usage;
	}
	metadata def <reply> ReplyMetadata :> SemanticMetadata {
		:>> baseType = replies meta SysML::Usage;
	}
	metadata def <documentMessage> DocumentMessageMetadata :> SemanticMetadata {
		:>> baseType = documentMessages meta SysML::Usage;
	}
	metadata def <channel> ChannelMetadata :> SemanticMetadata {
		:>> baseType = channels meta SysML::Usage;
	}
	metadata def <topic> TopicMetadata :> SemanticMetadata {
		:>> baseType = topics meta SysML::Usage;
	}
	metadata def <queue> QueueMetadata :> SemanticMetadata {
		:>> baseType = queues meta SysML::Usage;
	}
	metadata def <broker> MessageBrokerMetadata :> SemanticMetadata {
		:>> baseType = messageBrokers meta SysML::Usage;
	}

	/* Role keywords for flows / connections (flows are not always Types, so plain metadata). */
	metadata def <publishes> Publishes;
	metadata def <subscribes> Subscribes;
	metadata def <sends> Sends;
	metadata def <handles> Handles;
}
