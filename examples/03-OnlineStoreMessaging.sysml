package OnlineStoreMessaging {
	doc
	/*
	OnlineStoreMessaging: the event-driven messaging design of the online store, written in SysML v2 with
	UML3Messaging.

	Checkout asks the payment processor to capture a payment with a command and its reply, then publishes
	an OrderPlaced event to a Kafka topic that fulfillment consumes. The message types, endpoints, channels
	and flows are modeled first; the same exchange is then shown as an interaction (a UML sequence diagram).

	Contents:
	- Message schemas: OrderPlaced and PaymentCaptured (#domainEvent), CapturePayment (#command) and
	  PaymentResult (#reply), with @Serialization.
	- Endpoints: OrderEventsOut and OrderEventsIn (ProducerPort and ConsumerPort narrowed to OrderPlaced),
	  PaymentClientPort (RequestReplyPort).
	- Channels: OrderEventsTopic (#topic with @QualityOfService), hosted by KafkaCluster (#broker).
	- Participants: CheckoutService, PaymentProcessor and FulfillmentService (#service, @Idempotent).
	- Wiring: eventDrivenStore with #publishes, #subscribes, #sends and #handles flows.
	- Interaction: CheckoutInteraction with lifelines, event occurrences, successions and messages.
	References: docs/UML2-to-UML3-Traceability.md.
	*/
	private import ScalarValues::*;
	private import UML3Core::*;
	private import UML3Types::*;
	private import UML3Components::*;
	private import UML3Messaging::*;

	comment MessageKinds about OrderPlaced, CapturePayment, PaymentResult, PaymentCaptured
		/*
		Message kinds. The keyword states the intent of a message: a #domainEvent reports a fact that has
		happened and may have any number of subscribers, a #command asks exactly one handler to act, and a
		#reply answers a command. Each is a UML3Messaging::MessageType, so it inherits the header envelope
		(UML3Messaging::MessageHeader) and declares only its payload. @Serialization states the wire
		format: Avro with a schema file for OrderPlaced and JSON for CapturePayment; PaymentResult and
		PaymentCaptured declare none.
		References: UML3Messaging::DomainEvent; UML3Messaging::Command; UML3Messaging::Reply.
		*/

	#domainEvent item def OrderPlaced {
		doc
		/*
		The event that an order was placed, with its order, customer and total.

		A #domainEvent encoded with Avro; schemaRef names its schema file.
		*/
		@Serialization { format = SerializationFormat::avro; schemaRef = "schemas/order-placed-v1.avsc"; }
		attribute orderId : Uuid { doc /* The order that was placed. */ }
		attribute customerId : Uuid { doc /* The customer who placed the order. */ }
		attribute total : Money { doc /* The total amount of the order. */ }
		attribute currency : CurrencyCode { doc /* The currency of total. */ }
	}

	#command item def CapturePayment {
		doc
		/*
		The command that asks the payment processor to capture the payment for an order.

		A #command encoded as JSON; PaymentResult is its reply.
		*/
		@Serialization { format = SerializationFormat::json; }
		attribute orderId : Uuid { doc /* The order to be paid. */ }
		attribute amount : Money { doc /* The amount to capture. */ }
	}

	#reply item def PaymentResult {
		doc
		/*
		The reply to CapturePayment: whether the payment was approved and, if not, why.

		A #reply; the requester matches it to its command by header.correlationId.
		*/
		attribute orderId : Uuid { doc /* The order the payment was for. */ }
		attribute approved : Boolean { doc /* True when the payment was approved. */ }
		attribute declineCode : String[0..1] { doc /* The reason for a declined payment, if any. */ }
	}

	#domainEvent item def PaymentCaptured {
		doc
		/*
		The event that the payment for an order was captured, with the provider's payment reference.

		A #domainEvent of the message catalog; no port or flow of this example carries it.
		*/
		attribute orderId : Uuid { doc /* The order that was paid. */ }
		attribute paymentReference : String { doc /* The payment provider's reference for the capture. */ }
	}

	comment TypedEndpoints about OrderEventsOut, OrderEventsIn, PaymentClientPort
		/*
		Typed endpoints. The library ports carry any MessageType; these port defs narrow them to concrete
		messages by redefining the directed items with ':>>', so each endpoint states which message it
		carries. OrderEventsOut emits OrderPlaced and OrderEventsIn receives it. PaymentClientPort is the
		client side of a request/reply exchange, request out and response in; the server side uses the
		conjugate ~PaymentClientPort, which reverses both directions.
		References: UML3Messaging::ProducerPort; UML3Messaging::ConsumerPort; UML3Messaging::RequestReplyPort.
		*/

	port def OrderEventsOut :> ProducerPort {
		doc /* The endpoint that emits OrderPlaced events: a ProducerPort narrowed to OrderPlaced. */
		out item :>> outboundMessages : OrderPlaced[0..*];
	}

	port def OrderEventsIn :> ConsumerPort {
		doc /* The endpoint that receives OrderPlaced events: a ConsumerPort narrowed to OrderPlaced. */
		in item :>> inboundMessages : OrderPlaced[0..*];
	}

	port def PaymentClientPort :> RequestReplyPort {
		doc
		/*
		The client endpoint of the payment exchange: it sends CapturePayment and receives PaymentResult.

		A RequestReplyPort narrowed to the payment messages; the payment processor uses its conjugate.
		*/
		out item :>> request : CapturePayment[0..1];
		in item :>> response : PaymentResult[0..1];
	}

	#topic part def OrderEventsTopic {
		doc
		/*
		The topic store.orders.v1 that carries OrderPlaced events from the publisher to its subscribers.

		A #topic (UML3Messaging::Topic), a publish/subscribe channel with 12 partitions. @QualityOfService
		states its delivery contract: at-least-once delivery, ordering per key with orderId as the partition
		key, retention for 7 days (P7D) and the dead-letter channel store.orders.v1.dlq. Published events
		arrive at the inbound port and are delivered to subscribers from the outbound port.
		*/
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
		doc
		/*
		The Apache Kafka 3.8 cluster that hosts the order events topic.

		A #broker (UML3Messaging::MessageBroker, a component); its topics are parts of it.
		*/
		@Technology { technologyName = "Apache Kafka"; technologyVersion = "3.8"; }
		part ordersTopic : OrderEventsTopic { doc /* The order events topic hosted by the cluster. */ }
	}

	#service part def CheckoutService {
		doc
		/*
		The service that completes a checkout: it has the payment captured, then announces the placed order.

		A #service that publishes OrderPlaced events and is the client of the payment exchange.
		*/
		port events : OrderEventsOut { doc /* Emits OrderPlaced events. */ }
		port payments : PaymentClientPort { doc /* Sends CapturePayment and receives PaymentResult. */ }
	}

	#service part def PaymentProcessor {
		doc
		/*
		The service that captures payments on request.

		The server side of the payment exchange, so its port is typed by the conjugate ~PaymentClientPort.
		*/
		port payments : ~PaymentClientPort { doc /* Receives CapturePayment and sends PaymentResult. */ }
	}

	#service part def FulfillmentService {
		doc
		/*
		The service that fulfills placed orders; it consumes OrderPlaced events.

		@Idempotent declares that handling the same event twice has the same effect as handling it once,
		which the at-least-once delivery of OrderEventsTopic requires.
		*/
		@Idempotent;
		port events : OrderEventsIn { doc /* Receives OrderPlaced events. */ }
	}

	part eventDrivenStore {
		doc
		/*
		The running event-driven store: checkout, the Kafka cluster, fulfillment and the payment processor,
		connected by message flows.

		Each flow is a native SysML v2 flow of a message type from an out item to an in item, marked with
		its messaging role: #publishes, #subscribes, #sends or #handles.
		*/
		part checkout : CheckoutService { doc /* The checkout service. */ }
		part kafka : KafkaCluster { doc /* The Kafka cluster with the order events topic. */ }
		part fulfillment : FulfillmentService { doc /* The fulfillment service. */ }
		part paymentProcessor : PaymentProcessor { doc /* The payment processor. */ }

		comment PublishSubscribePath about publishOrderPlaced, consumeOrderPlaced
			/*
			Publish/subscribe path of OrderPlaced. The event leaves checkout through the out item of
			checkout.events, enters the topic at its inbound port, leaves the topic at its outbound port and
			reaches fulfillment through the in item of fulfillment.events. No flow connects checkout to
			fulfillment directly: the topic decouples the publisher from its subscribers, and another
			subscriber needs only one more #subscribes flow.
			References: UML3Messaging::Publishes; UML3Messaging::Subscribes; SysML 7.16.
			*/
		#publishes flow publishOrderPlaced of OrderPlaced from checkout.events.outboundMessages
			to kafka.ordersTopic.inbound.inboundMessages {
			doc /* Checkout publishes OrderPlaced to the order events topic. */
		}
		#subscribes flow consumeOrderPlaced of OrderPlaced from kafka.ordersTopic.outbound.outboundMessages
			to fulfillment.events.inboundMessages {
			doc /* The topic delivers OrderPlaced to its subscriber, fulfillment. */
		}

		comment RequestReplyPath about sendCapturePayment, returnPaymentResult
			/*
			Request/reply path of the payment. sendCapturePayment carries the command from the request
			item of checkout.payments (out) to the request item of paymentProcessor.payments, which is in
			because that port is conjugated. returnPaymentResult carries the reply back from the response
			item of the processor (out, by conjugation) to the response item of checkout (in). No broker is
			involved.
			References: UML3Messaging::Sends; UML3Messaging::Handles.
			*/
		#sends flow sendCapturePayment of CapturePayment from checkout.payments.request
			to paymentProcessor.payments.request {
			doc /* Checkout sends CapturePayment to the payment processor. */
		}
		#handles flow returnPaymentResult of PaymentResult from paymentProcessor.payments.response
			to checkout.payments.response {
			doc /* The payment processor, as the handler, returns PaymentResult to checkout. */
		}
	}

	occurrence def CheckoutInteraction {
		doc
		/*
		The checkout exchange as a UML sequence diagram: payment capture, then the order announcement.

		A native SysML v2 interaction, so no UML3 keyword is needed: the occurrence def is the interaction,
		its part usages are the lifelines, event occurrences are the points where a lifeline sends or
		receives a message, and messages connect those events (see MessageOrdering).
		References: UML 2.5.1 Interaction; UML 2.5.1 Lifeline; UML 2.5.1 Message; SysML 7.16.
		*/
		part checkoutLifeline : CheckoutService {
			doc /* The lifeline of the checkout service. */
			event occurrence requestPayment { doc /* Checkout sends the payment request. */ }
			event occurrence paymentConfirmed { doc /* Checkout receives the payment result. */ }
			event occurrence announceOrder { doc /* Checkout publishes OrderPlaced. */ }
			first requestPayment then paymentConfirmed;
			first paymentConfirmed then announceOrder;
		}
		part processorLifeline : PaymentProcessor {
			doc /* The lifeline of the payment processor. */
			event occurrence receiveRequest { doc /* The processor receives the payment request. */ }
			event occurrence sendResult { doc /* The processor sends the payment result. */ }
			first receiveRequest then sendResult;
		}
		part brokerLifeline : KafkaCluster {
			doc /* The lifeline of the Kafka cluster. */
			event occurrence receiveOrder { doc /* The broker receives OrderPlaced. */ }
		}

		comment MessageOrdering about capture, result, publish
			/*
			Sequence order. A message goes from an event on one lifeline to an event on another; the order of
			the messages comes from the successions ('first ... then ...') on each lifeline, not from the
			order of the text. On checkoutLifeline, requestPayment precedes paymentConfirmed, which precedes
			announceOrder; on processorLifeline, receiveRequest precedes sendResult. So capture comes before
			result, and the order is published only after the payment is confirmed.
			References: UML 2.5.1 GeneralOrdering; UML 2.5.1 OccurrenceSpecification.
			*/
		message capture of CapturePayment from checkoutLifeline.requestPayment to processorLifeline.receiveRequest {
			doc /* The CapturePayment command from checkout to the payment processor. */
		}
		message result of PaymentResult from processorLifeline.sendResult to checkoutLifeline.paymentConfirmed {
			doc /* The PaymentResult reply from the payment processor to checkout. */
		}
		message publish of OrderPlaced from checkoutLifeline.announceOrder to brokerLifeline.receiveOrder {
			doc /* The OrderPlaced event from checkout to the broker. */
		}
	}
}
