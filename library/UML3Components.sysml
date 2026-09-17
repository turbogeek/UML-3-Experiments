library package UML3Components {
	doc
	/*
	UML3Components: the software architecture constructs of UML3, defined as a SysML v2 model library.

	It covers components with provided and required interfaces, connectors, artifacts, nodes and
	deployment. Components are part defs that own SysML ports. A port def binds its contract, an
	InterfaceType of UML3Core; a provided port is typed by the port def and a required port by its
	conjugate (~PortDef). Connectors are SysML connections; deployment and manifestation are SysML
	allocations. As in UML3Core, each concept is an abstract library definition plus a semantic keyword
	that makes the annotated element specialize it:
	  #service part def OrderService { #provided port orderApi : OrderApiPort; }
	  #deploy allocate orderImage to nodeA.pods;
	A complete architecture is in examples/02-OnlineStoreArchitecture.sysml.

	Rationale: SysML v2 ports, connections and allocations are reused rather than redefined, so
	architecture models stay analyzable by any SysML v2 tool. UML3 adds the component vocabulary and
	the provided and required reading of port conjugation.

	Contents:
	- Components: Component, Subsystem, Service (#component, #subsystem, #service).
	- Ports: ServicePort (#servicePort), marked with Provided or Required (#provided, #required).
	- Connectors: AssemblyConnector, DelegationConnector (#assembly, #delegation).
	- Artifacts and nodes: Artifact, Node, Device, ExecutionEnvironment
	  (#artifact, #node, #device, #executionEnvironment).
	- Deployment: CommunicationPath, Deployment, Manifestation (#communicationPath, #deploy, #manifest).
	- Architecture metadata: Boundary (#boundary), Layer with ArchitectureStyle (@Layer), @Technology.
	References: UML 2.5.1 Component; UML 2.5.1 Deployment; SysML 7.12; SysML 7.15; docs/DESIGN.md.
	*/

	private import ScalarValues::*;
	private import Base::Anything;
	private import Metaobjects::SemanticMetadata;
	private import UML3Core::*;

	comment ComponentDesign about Component, Subsystem, Service
		/*
		Components. A component is a part def that specializes UML3Core::ActiveClass: a structural unit
		that owns ports, parts and connectors and can perform behavior. Subsystem and Service specialize
		Component, so a #service part def is also a Component and an ActiveClass; CATIA Magic confirms
		both implied specializations (tests/cameo/implied-specializations.json).
		Deviation: in UML 2.5.1 a component is active only when isActive is set; every UML3 component is
		an active class.
		References: UML 2.5.1 Component; UML 2.5.1 Class (isActive); SysML 7.11; SysML 7.27.3.
		*/

	abstract part def Component :> ActiveClass {
		doc
		/*
		UML Component: a replaceable, encapsulated unit exposing behavior only through ports.

		Usage: apply #component to a part def and give it #provided and #required ports; a composite
		component wires its parts with #assembly and #delegation connectors.
		  #component part def WebStorefront { #required port orderApi : ~OrderApiPort; }

		Rationale: a part def, because a component is a modular unit of structure that owns ports and
		parts and performs behavior.
		References: UML 2.5.1 Component; SysML 7.11; SysML 7.12.
		*/
	}
	abstract part components : Component[0..*] nonunique :> activeClasses {
		doc /* All components; #component usages subset this feature. */
	}

	abstract part def Subsystem :> Component {
		doc
		/*
		A large-grained component that groups other components.

		Usage: #subsystem part def StoreSystem { part web : WebStorefront; part orders : OrderService; }
		UML 2.5.1 expresses the same with the standard stereotype «Subsystem» on a component.
		References: UML 2.5.1 Component.
		*/
	}
	abstract part subsystems : Subsystem[0..*] nonunique :> components {
		doc /* All subsystems; #subsystem usages subset this feature. */
	}

	abstract part def Service :> Component {
		doc
		/*
		A deployable service (e.g. microservice) with a network-facing API.

		Usage: #service part def OrderService { attribute :>> serviceName = "order-service"; }
		Service is not a UML 2.5.1 metaclass; it is the component kind of service-oriented architectures.
		References: UML 2.5.1 Component.
		*/
		attribute serviceName : String[0..1] {
			doc /* The name that identifies the service at runtime, e.g. "order-service". */
		}
		attribute serviceVersion : String[0..1] {
			doc /* The version of the service, e.g. "2.1". */
		}
	}
	abstract part services : Service[0..*] nonunique :> components {
		doc /* All services; #service usages subset this feature. */
	}

	comment PortContractDesign about ServicePort, Provided, Required, AssemblyConnector, DelegationConnector
		/*
		Provided and required interfaces. A UML port with a provided or required interface is a SysML port
		whose port def binds a contract, an InterfaceType. One port def serves both sides of the contract:
		the providing component types its port with the port def and marks it #provided, the consuming
		component types its port with the conjugate ~PortDef and marks it #required. This follows UML 2.5.1,
		where a port derives its provided and required interfaces from its type and swaps them when the
		port is conjugated. An #assembly connector joins a required port to a provided port; a #delegation
		connector forwards a port of a component to a port of one of its parts. check_rules.py reports a
		conjugated #provided port or an unconjugated #required port (R07) and an unconnected #required
		port (R08).
		References: UML 2.5.1 Port (isConjugated); UML 2.5.1 Connector; SysML 7.12.3; KerML 7.3.2.4.
		*/

	abstract port def ServicePort {
		doc
		/*
		A UML port that exposes (or requires) a contract: the interface bound to 'contract'.

		Usage: bind the contract in a specialization, then type the ports of both sides with it:
		  port def OrderApiPort :> ServicePort { ref item :>> contract : OrderManagement; }
		  #provided port orderApi : OrderApiPort;     in the providing component
		  #required port orderApi : ~OrderApiPort;    in the consuming component
		References: UML 2.5.1 Port; UML 2.5.1 Interface; SysML 7.12.
		*/
		abstract ref item contract : InterfaceType[0..1] {
			doc /* The interface the port provides, or requires when the port is conjugated; bind it with ':>>'. */
		}
	}
	abstract port servicePorts : ServicePort[0..*] nonunique {
		doc /* All service ports; #servicePort usages subset this feature. */
	}

	abstract connection def AssemblyConnector {
		doc
		/*
		UML assembly connector: wires a required port of one component to a provided port of another.

		Usage: in the definition that owns both parts:
		  #assembly connect web.orderApi to orders.orderApi;
		References: UML 2.5.1 Connector; SysML 7.13.
		*/
	}
	abstract connection assemblyConnectors : AssemblyConnector[0..*] nonunique {
		doc /* All assembly connections; #assembly usages subset this feature. */
	}

	abstract connection def DelegationConnector {
		doc
		/*
		UML delegation connector: forwards an outer port of a component to a port of an internal part.

		Usage: in the component, from its own port to the port of the part that does the work:
		  #delegation connect orderApi to orders.orderApi;
		References: UML 2.5.1 Connector; SysML 7.13.
		*/
	}
	abstract connection delegationConnectors : DelegationConnector[0..*] nonunique {
		doc /* All delegation connections; #delegation usages subset this feature. */
	}

	comment DeploymentDesign about Artifact, Node, Device, ExecutionEnvironment, CommunicationPath,
		Deployment, Manifestation
		/*
		Deployment. Artifacts are item defs: they are stored, copied and deployed but perform no actions.
		Nodes, devices and execution environments are part defs: structural resources that contain one
		another, such as pods in a worker node. A communication path is a connection def between nodes.
		Deployment and manifestation are SysML allocations, whose target realizes the intent of the source,
		so both read from the logical side to the physical side:
		  #manifest allocate logical.orders to orderImage;    the artifact implements the component
		  #deploy allocate orderImage to nodeA.pods;          the execution environment hosts the artifact
		UML 2.5.1 draws a manifestation the other way, as a dependency from the artifact to the element it
		manifests.
		References: UML 2.5.1 Deployment; UML 2.5.1 Manifestation; SysML 7.10; SysML 7.11; SysML 7.15.
		*/

	abstract item def Artifact {
		doc
		/*
		UML Artifact: a physical piece of information (binary, container image, script, schema file).

		Usage: #artifact item def OrderServiceImage { attribute :>> artifactVersion = "1.4.2"; }
		Rationale: an item def, because an artifact is acted on (built, stored, deployed) and performs no
		actions itself.
		References: UML 2.5.1 Artifact; SysML 7.10.
		*/
		attribute fileName : String[0..1] {
			doc /* The concrete name that refers to the artifact, e.g. a file path or an image reference. */
		}
		attribute artifactVersion : String[0..1] {
			doc /* The version of the artifact, e.g. "1.4.2". */
		}
	}
	abstract item artifacts : Artifact[0..*] nonunique {
		doc /* All artifacts; #artifact usages subset this feature. */
	}

	abstract part def Node {
		doc
		/*
		UML Node: a computational resource on which artifacts are deployed.

		Usage: #node part def CloudRegion;
		Nodes nest, e.g. execution environments inside a device.
		Rationale: a part def, because a node is a structural resource that contains other nodes and is
		connected to them by communication paths.
		References: UML 2.5.1 Node; SysML 7.11.
		*/
	}
	abstract part nodes : Node[0..*] nonunique {
		doc /* All nodes; #node usages subset this feature. */
	}

	abstract part def Device :> Node {
		doc
		/*
		UML Device: a physical computational resource (server, phone, controller).

		Usage: #device part def WorkerNode { part pods : KubernetesPod[1..*]; }
		References: UML 2.5.1 Device.
		*/
	}
	abstract part devices : Device[0..*] nonunique :> nodes {
		doc /* All devices; #device usages subset this feature. */
	}

	abstract part def ExecutionEnvironment :> Node {
		doc
		/*
		UML ExecutionEnvironment: a software execution host (OS, JVM, container runtime, Kubernetes pod,
		browser).

		Usage: declare it, then nest it in the device that runs it:
		  #executionEnvironment part def KubernetesPod;
		  #device part def WorkerNode { part pods : KubernetesPod[1..*]; }
		References: UML 2.5.1 ExecutionEnvironment.
		*/
	}
	abstract part executionEnvironments : ExecutionEnvironment[0..*] nonunique :> nodes {
		doc /* All execution environments; #executionEnvironment usages subset this feature. */
	}

	abstract connection def CommunicationPath {
		doc
		/*
		UML CommunicationPath: a connection between nodes over which they exchange signals and messages.

		Usage: declare one end per node:
		  #communicationPath connection def ClusterNetwork {
		    end [1] ref fromNode : WorkerNode;
		    end [1] ref toNode : WorkerNode;
		    attribute :>> protocol = "TCP/HTTP2";
		  }
		References: UML 2.5.1 CommunicationPath; SysML 7.13.
		*/
		attribute protocol : String[0..1] {
			doc /* The communication protocol used on the path, e.g. "TCP/HTTP2". */
		}
	}
	abstract connection communicationPaths : CommunicationPath[0..*] nonunique {
		doc /* All communication paths; #communicationPath usages subset this feature. */
	}

	allocation def Deployment {
		doc
		/*
		UML Deployment: allocates an artifact (or component) to the node that hosts it.

		Usage: #deploy allocate orderImage to nodeA.pods;
		In UML 2.5.1 only artifacts are deployed; a component reaches a node through the artifact that
		manifests it.
		References: UML 2.5.1 Deployment; SysML 7.15.
		*/
	}
	abstract allocation deployments : Deployment[0..*] nonunique {
		doc /* All deployments; #deploy usages subset this feature. */
	}

	allocation def Manifestation {
		doc
		/*
		UML Manifestation: allocates a component (logical) to the artifact that implements it.

		Usage: #manifest allocate logical.orders to orderImage;
		References: UML 2.5.1 Manifestation; SysML 7.15.
		*/
	}
	abstract allocation manifestations : Manifestation[0..*] nonunique {
		doc /* All manifestations; #manifest usages subset this feature. */
	}

	comment ComponentKeywordDesign about ComponentMetadata, SubsystemMetadata, ServiceMetadata,
		ServicePortMetadata, AssemblyMetadata, DelegationMetadata, ArtifactMetadata, NodeMetadata,
		DeviceMetadata, ExecutionEnvironmentMetadata, CommunicationPathMetadata, DeploymentMetadata,
		ManifestationMetadata
		/*
		Semantic keywords of the architecture concepts, built like those of UML3Core: each specializes
		SemanticMetadata and redefines baseType to the collection usage of its concept. A keyworded
		definition then specializes the concept's definition, and a keyworded usage subsets the collection.
		References: KerML 9.2.16; SysML 7.27.3; SysML 7.27.4.
		*/

	metadata def <component> ComponentMetadata :> SemanticMetadata {
		doc /* Keyword #component: the element is a UML3 Component; a usage subsets components. */
		:>> baseType = components meta SysML::Usage;
	}

	metadata def <subsystem> SubsystemMetadata :> SemanticMetadata {
		doc /* Keyword #subsystem: the element is a UML3 Subsystem, a component that groups other components. */
		:>> baseType = subsystems meta SysML::Usage;
	}

	metadata def <service> ServiceMetadata :> SemanticMetadata {
		doc /* Keyword #service: the element is a UML3 Service, a deployable component with a network API. */
		:>> baseType = services meta SysML::Usage;
	}

	metadata def <servicePort> ServicePortMetadata :> SemanticMetadata {
		doc /* Keyword #servicePort: a port def specializes ServicePort, a port usage subsets servicePorts. */
		:>> baseType = servicePorts meta SysML::Usage;
	}

	metadata def <assembly> AssemblyMetadata :> SemanticMetadata {
		doc /* Keyword #assembly: the connection is an AssemblyConnector from a required to a provided port. */
		:>> baseType = assemblyConnectors meta SysML::Usage;
	}

	metadata def <delegation> DelegationMetadata :> SemanticMetadata {
		doc /* Keyword #delegation: the connection is a DelegationConnector (component port to part port). */
		:>> baseType = delegationConnectors meta SysML::Usage;
	}

	metadata def <artifact> ArtifactMetadata :> SemanticMetadata {
		doc /* Keyword #artifact: the element is a UML3 Artifact. */
		:>> baseType = artifacts meta SysML::Usage;
	}

	metadata def <node> NodeMetadata :> SemanticMetadata {
		doc /* Keyword #node: the element is a UML3 Node, a computational resource. */
		:>> baseType = nodes meta SysML::Usage;
	}

	metadata def <device> DeviceMetadata :> SemanticMetadata {
		doc /* Keyword #device: the element is a UML3 Device, a physical computational resource. */
		:>> baseType = devices meta SysML::Usage;
	}

	metadata def <executionEnvironment> ExecutionEnvironmentMetadata :> SemanticMetadata {
		doc /* Keyword #executionEnvironment: the element is a UML3 ExecutionEnvironment, a software host. */
		:>> baseType = executionEnvironments meta SysML::Usage;
	}

	metadata def <communicationPath> CommunicationPathMetadata :> SemanticMetadata {
		doc /* Keyword #communicationPath: the connection is a UML3 CommunicationPath between nodes. */
		:>> baseType = communicationPaths meta SysML::Usage;
	}

	metadata def <deploy> DeploymentMetadata :> SemanticMetadata {
		doc /* Keyword #deploy: the allocation is a UML3 Deployment of an artifact to the node that hosts it. */
		:>> baseType = deployments meta SysML::Usage;
	}

	metadata def <manifest> ManifestationMetadata :> SemanticMetadata {
		doc /* Keyword #manifest: the allocation is a UML3 Manifestation of a component in an artifact. */
		:>> baseType = manifestations meta SysML::Usage;
	}

	comment ArchitectureMarkerDesign about providedPorts, requiredPorts, boundaryElements, Provided,
		Required, Boundary
		/*
		Marker keywords, built with the marker pattern of UML3Core: the baseType is a reference usage typed
		by Base::Anything, which belongs to no disjoint type family, so a marker is valid on plain and
		conjugated ports, on parts and on definitions. A marked usage subsets the marker set, e.g.
		providedPorts. On a definition the implied specialization is only Anything, so a marked definition
		is found by its metadata, e.g. filter @Boundary.
		CATIA Magic shows the markers as labels («#provided», «#required», «#boundary») but applies the
		implied specialization of only the first semantic keyword of an element (E02, E03). Write the concept
		keyword first, as in #component #boundary part def WebStorefront; check_rules.py R12 warns when a
		usage stacks semantic keywords.
		References: KerML 7.3.2.5; SysML 7.27.3; E01; E02; E03.
		*/

	abstract ref providedPorts : Anything[0..*] nonunique {
		doc /* All ports marked #provided. */
	}
	abstract ref requiredPorts : Anything[0..*] nonunique {
		doc /* All ports marked #required. */
	}
	abstract ref boundaryElements : Anything[0..*] nonunique {
		doc /* All usages marked #boundary; a marked definition only carries the metadata. */
	}

	metadata def <provided> Provided :> SemanticMetadata {
		doc
		/*
		Keyword #provided: the port offers its contract to others (UML provided interface / lollipop).

		Usage: #provided port orderApi : OrderApiPort;
		The port must not be typed by a conjugated port def (check_rules.py R07).
		References: UML 2.5.1 Port; UML 2.5.1 Interface.
		*/
		:>> baseType = providedPorts meta SysML::Usage;
	}

	metadata def <required> Required :> SemanticMetadata {
		doc
		/*
		Keyword #required: the port needs its contract from others (UML required interface / socket).

		Usage: type the port with the conjugated port def and connect it with an #assembly connector:
		  #required port paymentApi : ~PaymentApiPort;
		check_rules.py reports an unconjugated #required port (R07) and an unconnected one (R08).
		References: UML 2.5.1 Port; UML 2.5.1 Interface; SysML 7.12.3.
		*/
		:>> baseType = requiredPorts meta SysML::Usage;
	}

	comment ArchitectureMetadataDesign about ArchitectureStyle, Layer, Technology
		/*
		Architecture metadata. Layer and Technology are plain metadata, not semantic keywords: they carry
		values and add no specialization, and a layer is usually a package, which semantic metadata cannot
		annotate because its annotated elements must be types. CATIA Magic does not show plain metadata in
		the keyword label of a shape.
		References: SysML 7.27.2; SysML 7.27.3.
		*/

	enum def ArchitectureStyle {
		doc
		/*
		An architecture style, the value of the 'style' attribute of Layer.

		Usage: @Layer { level = 1; style = ArchitectureStyle::layered; }
		*/
		enum layered {
			doc /* Layers ordered by level; each layer uses the services of the layers below it. */
		}
		enum hexagonal {
			doc /* Ports and adapters: a technology-independent core reached through #boundary adapters. */
		}
		enum microservices {
			doc /* Independently deployable #service components that communicate over the network. */
		}
		enum eventDriven {
			doc /* Components that communicate by publishing and consuming events through channels. */
		}
		enum clientServer {
			doc /* Clients that send requests to servers providing shared services. */
		}
		enum pipesAndFilters {
			doc /* Filters that each transform data, connected in sequence by pipes. */
		}
	}

	metadata def <layer> Layer {
		doc
		/*
		Plain metadata that marks a package (or component) as an architectural layer.

		Usage: package Presentation { @Layer { level = 1; style = ArchitectureStyle::layered; } }
		*/
		attribute level : Natural[0..1] {
			doc /* The position of the layer in its stack; examples/02 gives presentation 1 and application 2. */
		}
		attribute style : ArchitectureStyle[0..1] {
			doc /* The architecture style the layer belongs to. */
		}
	}

	metadata def <boundary> Boundary :> SemanticMetadata {
		doc
		/*
		Keyword #boundary: a hexagonal or clean-architecture boundary element (adapter, port, gateway).

		Usage: #component #boundary part def WebStorefront { ... }
		References: E01.
		*/
		:>> baseType = boundaryElements meta SysML::Usage;
	}

	metadata def Technology {
		doc
		/*
		Plain metadata recording an implementation technology choice and its version.

		Usage: @Technology { technologyName = "Spring Boot"; technologyVersion = "3.3"; }
		It has no annotatedElement restriction; examples/02 applies it to components and execution
		environments.
		Rationale: UML3 has no DeploymentSpecification classifier; deployment properties are recorded as
		@Technology metadata or as attributes of the node or artifact.
		References: UML 2.5.1 DeploymentSpecification.
		*/
		attribute technologyName : String {
			doc /* The name of the technology, e.g. "Spring Boot" or "Kubernetes". */
		}
		attribute technologyVersion : String[0..1] {
			doc /* The version of the technology, e.g. "3.3". */
		}
	}
}
