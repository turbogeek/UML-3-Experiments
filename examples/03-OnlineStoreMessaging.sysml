package OnlineStoreMessaging {
	doc
	/*
	 * Example 3 - Messaging / event-driven design.
	 * Demonstrates: message schemas (commands, domain events, replies) with
	 * serialization metadata, topics and brokers with QoS, producer/consumer
	 * ports, publish/subscribe flows, and an interaction (sequence diagram).
	 */
	private import ScalarValues::*;
	private import UML3Core::*;
	private import UML3Types::*;
	private import UML3Components::*;
	private import UML3Messaging::*;

	/* --- Message schemas -------------------------------------------------- */

	#domainEvent item def OrderPlaced {
		@Serialization { format = SerializationFormat::avro; schemaRef = "schemas/order-placed-v1.avsc"; }
		attribute orderId : Uuid;
		attribute customerId : Uuid;
		attribute total : Money;
		attribute currency : CurrencyCode;
	}

	#command item def CapturePayment {
		@Serialization { format = SerializationFormat::json; }
		attribute orderId : Uuid;
		attribute amount : Money;
	}

	#reply item def PaymentResult {
		attribute orderId : Uuid;
		attribute approved : Boolean;
		attribute declineCode : String[0..1];
	}

	#domainEvent item def PaymentCaptured {
		attribute orderId : Uuid;
		attribute paymentReference : String;
	}

	/* --- Endpoints (narrow the generic ports to concrete message types) --- */

	port def OrderEventsOut :> ProducerPort {
		out item :>> outboundMessages : OrderPlaced[0..*];
	}

	port def OrderEventsIn :> ConsumerPort {
		in item :>> inboundMessages : OrderPlaced[0..*];
	}

	port def PaymentClientPort :> RequestReplyPort {
		out item :>> request : CapturePayment[0..1];
		in item :>> response : PaymentResult[0..1];
	}

	/* --- Channels and broker --------------------------------------------- */

	#topic part def OrderEventsTopic {
		@QualityOfService {
			delivery = DeliveryGuarantee::atLeastOnce;
			ordering = OrderingGuarantee::perKey;
			partitionKey = "orderId";
			retentionPeriod = "P7D";
			deadLetterChannel = "store.orders.v1.dlq";
		}
		attribute :>> channelName = "store.orders.v1";
		attribute :>> partitionCount = 12;
		port :>> inbound : OrderEventsIn;
		port :>> outbound : OrderEventsOut;
	}

	#broker part def KafkaCluster {
		@Technology { technologyName = "Apache Kafka"; technologyVersion = "3.8"; }
		part ordersTopic : OrderEventsTopic;
	}

	/* --- Participants -------------------------------------------------- */

	#service part def CheckoutService {
		port events : OrderEventsOut;
		port payments : PaymentClientPort;
	}

	#service part def PaymentProcessor {
		port payments : ~PaymentClientPort;
	}

	#service part def FulfillmentService {
		@Idempotent;
		port events : OrderEventsIn;
	}

	/* --- Wiring: publish / subscribe ---------------------------------- */

	part eventDrivenStore {
		part checkout : CheckoutService;
		part kafka : KafkaCluster;
		part fulfillment : FulfillmentService;
		part paymentProcessor : PaymentProcessor;

		#publishes flow of OrderPlaced from checkout.events.outboundMessages
			to kafka.ordersTopic.inbound.inboundMessages;
		#subscribes flow of OrderPlaced from kafka.ordersTopic.outbound.outboundMessages
			to fulfillment.events.inboundMessages;
		#sends flow of CapturePayment from checkout.payments.request
			to paymentProcessor.payments.request;
	}

	/* --- Interaction (UML sequence diagram) --------------------------- */

	occurrence def CheckoutInteraction {
		part checkoutLifeline : CheckoutService {
			event occurrence requestPayment;
			event occurrence paymentConfirmed;
			event occurrence announceOrder;
			first requestPayment then paymentConfirmed;
			first paymentConfirmed then announceOrder;
		}
		part processorLifeline : PaymentProcessor {
			event occurrence receiveRequest;
			event occurrence sendResult;
			first receiveRequest then sendResult;
		}
		part brokerLifeline : KafkaCluster {
			event occurrence receiveOrder;
		}

		/* Sequence order comes from the successions ('first ... then ...') on each lifeline. */
		message capture of CapturePayment from checkoutLifeline.requestPayment to processorLifeline.receiveRequest;
		message result of PaymentResult from processorLifeline.sendResult to checkoutLifeline.paymentConfirmed;
		message publish of OrderPlaced from checkoutLifeline.announceOrder to brokerLifeline.receiveOrder;
	}
}
