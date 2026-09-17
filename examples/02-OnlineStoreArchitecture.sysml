package OnlineStoreArchitecture {
	doc
	/*
	OnlineStoreArchitecture: the software architecture of the online store as UML component and deployment
	models, written in SysML v2 with UML3Components.

	The store's services offer and require contracts through ports, are assembled into StoreSystem, are
	assigned to layers and are deployed as a container image on a Kubernetes cluster. The contracts use
	the classes and interfaces of example 01 (OnlineStoreDomain).

	Contents:
	- Contracts: OrderManagement (#interfaceType); OrderApiPort and PaymentApiPort (ServicePort defs).
	- Components: WebStorefront (#component, #boundary), OrderService and PaymentService (#service), with
	  #provided and #required ports and @Technology; StoreSystem (#subsystem) with #assembly connectors.
	- Layers: Presentation and Application (#layer packages with @layer).
	- Deployment: OrderServiceImage (#artifact), KubernetesPod (#executionEnvironment), WorkerNode
	  (#device), ClusterNetwork (#communicationPath) and productionCluster with #manifest and #deploy
	  allocations.
	References: docs/UML2-to-UML3-Traceability.md.
	*/
	private import ScalarValues::*;
	private import UML3Core::*;
	private import UML3Components::*;
	private import OnlineStoreDomain::*;

	#interfaceType item def OrderManagement {
		doc
		/*
		The contract of the order service: placing orders.

		A UML Interface (#interfaceType) declared at the architecture level; OrderApiPort exposes it.
		*/
		abstract #operation action placeOrder {
			doc /* Places an order for buyer; placed is the new order. */
			in buyer : Customer;
			out placed : Order;
		}
	}

	port def OrderApiPort :> ServicePort {
		doc
		/*
		The port for the OrderManagement contract, used on both the providing and the consuming side.

		A UML3Components::ServicePort that binds contract to OrderManagement. OrderService provides it, and
		WebStorefront requires it through the conjugate ~OrderApiPort (see ProvidedAndRequiredPorts).
		*/
		ref item :>> contract : OrderManagement;
	}

	port def PaymentApiPort :> ServicePort {
		doc
		/*
		The port for the PaymentGateway contract of example 01.

		A UML3Components::ServicePort that binds contract to PaymentGateway. PaymentService provides it, and
		OrderService requires it through the conjugate ~PaymentApiPort.
		*/
		ref item :>> contract : PaymentGateway;
	}

	comment ProvidedAndRequiredPorts about OrderApiPort, PaymentApiPort, WebStorefront::orderApi,
		OrderService::orderApi, OrderService::paymentApi, PaymentService::paymentApi
		/*
		Provided and required ports. Each contract is exposed through one ServicePort def. The component that
		offers the contract types its port with the def and marks it #provided (UML lollipop); a component
		that needs the contract types its port with the conjugate (~) of the same def and marks it #required
		(UML socket). Conjugation reverses in and out features; ServicePort::contract has no direction, so
		here the conjugate only identifies the consuming side of the same contract. tools/check_rules.py R07
		checks that #provided ports are not conjugated and #required ports are.
		References: UML3Components::provided; UML3Components::required; UML 2.5.1 Port; SysML 7.12.3.
		*/

	#component #boundary part def WebStorefront {
		doc
		/*
		The web front end of the store, used by customers.

		A #component that is also a #boundary element: the adapter between the users and the services.
		#component is written first: CATIA Magic applies only the first semantic keyword of an element
		(E02, E03). @Technology records React 19.
		*/
		@Technology { technologyName = "React"; technologyVersion = "19"; }
		#required port orderApi : ~OrderApiPort { doc /* Requires OrderManagement to place orders. */ }
	}

	#service part def OrderService {
		doc
		/*
		The back-end service that places and manages orders.

		A #service (UML3Components::Service) built with Spring Boot 3.3. It provides OrderManagement through
		orderApi and requires PaymentGateway through paymentApi; serviceName is bound to "order-service".
		*/
		@Technology { technologyName = "Spring Boot"; technologyVersion = "3.3"; }
		attribute :>> serviceName = "order-service";
		#provided port orderApi : OrderApiPort { doc /* Provides OrderManagement to the storefront. */ }
		#required port paymentApi : ~PaymentApiPort { doc /* Requires PaymentGateway to take payments. */ }
	}

	#service part def PaymentService {
		doc
		/*
		The service that takes payments for orders.

		A #service that provides the PaymentGateway contract through paymentApi.
		*/
		attribute :>> serviceName = "payment-service";
		#provided port paymentApi : PaymentApiPort { doc /* Provides PaymentGateway to OrderService. */ }
	}

	#subsystem part def StoreSystem {
		doc
		/*
		The online store as one system: the storefront, the order service and the payment service, wired
		together.

		A #subsystem (UML3Components::Subsystem) whose parts are connected by #assembly connectors (see
		AssemblyWiring).
		*/
		part web : WebStorefront { doc /* The storefront. */ }
		part orders : OrderService { doc /* The order service. */ }
		part payments : PaymentService { doc /* The payment service. */ }

		comment AssemblyWiring about web, orders, payments
			/*
			Assembly. Each #assembly connector wires a required port to the provided port with the same
			contract: web.orderApi to orders.orderApi (OrderManagement), and orders.paymentApi to
			payments.paymentApi (PaymentGateway). An order placed in the storefront therefore reaches the
			order service, which uses the payment service. tools/check_rules.py R08 warns about a #required
			port that is not connected.
			References: UML3Components::AssemblyConnector; UML 2.5.1 Connector.
			*/
		#assembly connect web.orderApi to orders.orderApi;
		#assembly connect orders.paymentApi to payments.paymentApi;
	}

	comment LayerAssignment about Presentation, Application
		/*
		Layers. Each layer is a package marked #layer whose @layer metadata gives its position in the layer
		stack (level) and the architecture style. A component belongs to a layer through a usage of it
		inside the layer package: storefrontUi in Presentation, orderApplication in Application. These
		usages are separate from the parts of StoreSystem.
		References: UML3Components::layer.
		*/

	#layer package Presentation {
		doc
		/*
		The presentation layer: the user-facing part of the store, level 1 of the layered architecture.

		Contents:
		- Layer metadata: @layer with level 1 and the layered style.
		- storefrontUi: the web storefront in this layer.
		*/
		@layer { level = 1; style = ArchitectureStyle::layered; }
		part storefrontUi : WebStorefront { doc /* The web storefront in this layer. */ }
	}

	#layer package Application {
		doc
		/*
		The application layer: the services that carry out the store's business, level 2 of the layered
		architecture.

		Contents:
		- Layer metadata: @layer with level 2 and the layered style.
		- orderApplication: the order service in this layer.
		*/
		@layer { level = 2; style = ArchitectureStyle::layered; }
		part orderApplication : OrderService { doc /* The order service in this layer. */ }
	}

	#artifact item def OrderServiceImage {
		doc
		/*
		The container image of the order service in the image registry.

		A UML3Components::Artifact (#artifact); fileName and artifactVersion are bound to the image name and
		its version tag.
		*/
		attribute :>> fileName = "registry.example.com/store/order-service";
		attribute :>> artifactVersion = "1.4.2";
	}

	#executionEnvironment part def KubernetesPod {
		doc
		/*
		A Kubernetes pod: the execution environment in which a container image runs.

		A UML3Components::ExecutionEnvironment (#executionEnvironment); @Technology records Kubernetes 1.30.
		*/
		@Technology { technologyName = "Kubernetes"; technologyVersion = "1.30"; }
	}

	#device part def WorkerNode {
		doc
		/*
		A machine of the Kubernetes cluster that runs pods.

		A UML3Components::Device (#device) that contains execution environments.
		*/
		part pods : KubernetesPod[1..*] { doc /* The pods running on the node; at least one. */ }
	}

	#communicationPath connection def ClusterNetwork {
		doc
		/*
		The network link between two worker nodes, over TCP with HTTP/2.

		A UML3Components::CommunicationPath (#communicationPath) with its protocol bound. Both ends have
		multiplicity 1, which, read as UML end multiplicities, links each worker node to exactly one other
		node. productionCluster does not use it.
		*/
		end [1] ref fromNode : WorkerNode { doc /* The node at one end of the link. */ }
		end [1] ref toNode : WorkerNode { doc /* The node at the other end of the link. */ }
		attribute :>> protocol = "TCP/HTTP2";
	}

	part productionCluster {
		doc
		/*
		The production environment: the store system, the order service image and two worker nodes.

		A part usage that brings the logical and the physical architecture together (see DeploymentChain).
		*/
		part logical : StoreSystem { doc /* The logical store system whose components are deployed. */ }
		item orderImage : OrderServiceImage { doc /* The order service image used in production. */ }
		part nodeA : WorkerNode { doc /* The first worker node; its pods run the order service image. */ }
		part nodeB : WorkerNode { doc /* The second worker node; no deployment targets it here. */ }

		comment DeploymentChain about logical, orderImage, nodeA
			/*
			Manifestation and deployment. #manifest allocates the logical order service, logical.orders, to
			orderImage, the artifact that implements it; #deploy allocates orderImage to the pods of nodeA.
			Following both allocations answers where a component runs: the order service is built into the
			image, and the image runs in the pods of nodeA. Only the order service is manifested and deployed
			in this example.
			References: UML3Components::Manifestation; UML3Components::Deployment; SysML 7.15.
			*/
		#manifest allocate logical.orders to orderImage;
		#deploy allocate orderImage to nodeA.pods;
	}
}
