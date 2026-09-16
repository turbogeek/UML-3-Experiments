package OnlineStoreArchitecture {
	doc
	/*
	 * Example 2 - Software architecture (UML component + deployment diagrams).
	 * Demonstrates: services/components, provided (#provided) and required
	 * (#required, conjugated ~) ports bound to interface contracts, assembly
	 * connectors, layers, artifacts, nodes, execution environments, deployment
	 * and manifestation.
	 */
	private import ScalarValues::*;
	private import UML3Core::*;
	private import UML3Components::*;
	private import OnlineStoreDomain::*;

	/* --- Contracts exposed as ports ------------------------------------ */

	#interfaceType item def OrderManagement {
		abstract #operation action placeOrder {
			in buyer : Customer;
			out placed : Order;
		}
	}

	port def OrderApiPort :> ServicePort {
		ref item :>> contract : OrderManagement;
	}

	port def PaymentApiPort :> ServicePort {
		ref item :>> contract : PaymentGateway;
	}

	/* --- Components ------------------------------------------------------ */

	#component #boundary part def WebStorefront {
		@Technology { technologyName = "React"; technologyVersion = "19"; }
		#required port orderApi : ~OrderApiPort;
	}

	#service part def OrderService {
		@Technology { technologyName = "Spring Boot"; technologyVersion = "3.3"; }
		attribute :>> serviceName = "order-service";
		#provided port orderApi : OrderApiPort;
		#required port paymentApi : ~PaymentApiPort;
	}

	#service part def PaymentService {
		attribute :>> serviceName = "payment-service";
		#provided port paymentApi : PaymentApiPort;
	}

	#subsystem part def StoreSystem {
		part web : WebStorefront;
		part orders : OrderService;
		part payments : PaymentService;

		#assembly connect web.orderApi to orders.orderApi;
		#assembly connect orders.paymentApi to payments.paymentApi;
	}

	/* --- Layers ------------------------------------------------------------ */

	#layer package Presentation {
		@Layer { level = 1; style = ArchitectureStyle::layered; }
		part storefrontUi : WebStorefront;
	}

	#layer package Application {
		@Layer { level = 2; style = ArchitectureStyle::layered; }
		part orderApplication : OrderService;
	}

	/* --- Deployment -------------------------------------------------------- */

	#artifact item def OrderServiceImage {
		attribute :>> fileName = "registry.example.com/store/order-service";
		attribute :>> artifactVersion = "1.4.2";
	}

	#executionEnvironment part def KubernetesPod {
		@Technology { technologyName = "Kubernetes"; technologyVersion = "1.30"; }
	}

	#device part def WorkerNode {
		part pods : KubernetesPod[1..*];
	}

	#communicationPath connection def ClusterNetwork {
		end [1] ref fromNode : WorkerNode;
		end [1] ref toNode : WorkerNode;
		attribute :>> protocol = "TCP/HTTP2";
	}

	part productionCluster {
		part logical : StoreSystem;
		item orderImage : OrderServiceImage;
		part nodeA : WorkerNode;
		part nodeB : WorkerNode;

		#manifest allocate logical.orders to orderImage;
		#deploy allocate orderImage to nodeA.pods;
	}
}
