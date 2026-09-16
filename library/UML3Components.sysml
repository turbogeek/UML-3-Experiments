library package UML3Components {
	doc
	/*
	 * UML3Components - software architecture: components, provided/required
	 * interfaces, connectors, layers, artifacts, nodes and deployment.
	 *
	 * UML ports with provided/required interfaces map to SysML v2 ports:
	 *   - a ServicePort def names its contract (an InterfaceType) via 'contract'
	 *   - a provided port uses the port def directly and is marked #provided
	 *   - a required port uses the CONJUGATE (~PortDef) and is marked #required
	 * Assembly connectors are 'connect' / 'interface' usages between a provided
	 * and a required port; deployment uses SysML allocation.
	 */

	private import ScalarValues::*;
	private import Metaobjects::SemanticMetadata;
	private import UML3Core::*;

	/* ---------------------------------------------------------------------
	 * Components and ports
	 * --------------------------------------------------------------------- */

	abstract part def Component :> ActiveClass {
		doc /* UML Component: a replaceable, encapsulated unit exposing behavior only through ports. */
	}
	abstract part components : Component[0..*] nonunique :> activeClasses;

	abstract part def Subsystem :> Component {
		doc /* A large-grained component that groups other components. */
	}
	abstract part subsystems : Subsystem[0..*] nonunique :> components;

	abstract part def Service :> Component {
		doc /* A deployable service (e.g. microservice) with a network-facing API. */
		attribute serviceName : String[0..1];
		attribute serviceVersion : String[0..1];
	}
	abstract part services : Service[0..*] nonunique :> components;

	abstract port def ServicePort {
		doc
		/*
		 * A UML port that exposes (or requires) a contract. Bind the contract in a
		 * specialization: port def OrderApi :> ServicePort { ref item :>> contract : OrderService; }
		 */
		abstract ref item contract : InterfaceType[0..1];
	}
	abstract port servicePorts : ServicePort[0..*] nonunique;

	abstract connection def AssemblyConnector {
		doc /* Wires a required port of one component to a provided port of another. */
	}
	abstract connection assemblyConnectors : AssemblyConnector[0..*] nonunique;

	abstract connection def DelegationConnector {
		doc /* Forwards an outer port of a component to a port of an internal part. */
	}
	abstract connection delegationConnectors : DelegationConnector[0..*] nonunique;

	/* ---------------------------------------------------------------------
	 * Deployment
	 * --------------------------------------------------------------------- */

	abstract item def Artifact {
		doc /* UML Artifact: a physical piece of information (binary, container image, script, schema file). */
		attribute fileName : String[0..1];
		attribute artifactVersion : String[0..1];
	}
	abstract item artifacts : Artifact[0..*] nonunique;

	abstract part def Node {
		doc /* UML Node: a computational resource on which artifacts are deployed. */
	}
	abstract part nodes : Node[0..*] nonunique;

	abstract part def Device :> Node {
		doc /* A physical computational resource (server, phone, controller). */
	}
	abstract part devices : Device[0..*] nonunique :> nodes;

	abstract part def ExecutionEnvironment :> Node {
		doc /* Software execution host (OS, JVM, container runtime, Kubernetes pod, browser). */
	}
	abstract part executionEnvironments : ExecutionEnvironment[0..*] nonunique :> nodes;

	abstract connection def CommunicationPath {
		doc /* UML CommunicationPath between nodes. */
		attribute protocol : String[0..1];
	}
	abstract connection communicationPaths : CommunicationPath[0..*] nonunique;

	allocation def Deployment {
		doc /* UML Deployment: allocate an artifact (or component) to a node. */
	}
	abstract allocation deployments : Deployment[0..*] nonunique;

	allocation def Manifestation {
		doc /* UML Manifestation: allocate a component (logical) to the artifact that implements it. */
	}
	abstract allocation manifestations : Manifestation[0..*] nonunique;

	/* ---------------------------------------------------------------------
	 * Semantic keywords
	 * --------------------------------------------------------------------- */

	metadata def <component> ComponentMetadata :> SemanticMetadata {
		:>> baseType = components meta SysML::Usage;
	}
	metadata def <subsystem> SubsystemMetadata :> SemanticMetadata {
		:>> baseType = subsystems meta SysML::Usage;
	}
	metadata def <service> ServiceMetadata :> SemanticMetadata {
		:>> baseType = services meta SysML::Usage;
	}
	metadata def <servicePort> ServicePortMetadata :> SemanticMetadata {
		:>> baseType = servicePorts meta SysML::Usage;
	}
	metadata def <assembly> AssemblyMetadata :> SemanticMetadata {
		:>> baseType = assemblyConnectors meta SysML::Usage;
	}
	metadata def <delegation> DelegationMetadata :> SemanticMetadata {
		:>> baseType = delegationConnectors meta SysML::Usage;
	}
	metadata def <artifact> ArtifactMetadata :> SemanticMetadata {
		:>> baseType = artifacts meta SysML::Usage;
	}
	metadata def <node> NodeMetadata :> SemanticMetadata {
		:>> baseType = nodes meta SysML::Usage;
	}
	metadata def <device> DeviceMetadata :> SemanticMetadata {
		:>> baseType = devices meta SysML::Usage;
	}
	metadata def <executionEnvironment> ExecutionEnvironmentMetadata :> SemanticMetadata {
		:>> baseType = executionEnvironments meta SysML::Usage;
	}
	metadata def <communicationPath> CommunicationPathMetadata :> SemanticMetadata {
		:>> baseType = communicationPaths meta SysML::Usage;
	}
	metadata def <deploy> DeploymentMetadata :> SemanticMetadata {
		:>> baseType = deployments meta SysML::Usage;
	}
	metadata def <manifest> ManifestationMetadata :> SemanticMetadata {
		:>> baseType = manifestations meta SysML::Usage;
	}

	/* ---------------------------------------------------------------------
	 * Annotation-only keywords
	 * --------------------------------------------------------------------- */

	metadata def <provided> Provided {
		doc /* The port offers its contract to others (UML provided interface / lollipop). */
	}
	metadata def <required> Required {
		doc /* The port needs its contract from others (UML required interface / socket). Type it with ~PortDef. */
	}

	enum def ArchitectureStyle {
		enum layered;
		enum hexagonal;
		enum microservices;
		enum eventDriven;
		enum clientServer;
		enum pipesAndFilters;
	}

	metadata def <layer> Layer {
		doc /* Marks a package (or component) as an architectural layer. */
		attribute level : Natural[0..1];
		attribute style : ArchitectureStyle[0..1];
	}

	metadata def <boundary> Boundary {
		doc /* Hexagonal / clean-architecture boundary element (adapter, port, gateway). */
	}

	metadata def Technology {
		doc /* Implementation technology choice, e.g. @Technology { technologyName = "Spring Boot"; technologyVersion = "3.3"; } */
		attribute technologyName : String;
		attribute technologyVersion : String[0..1];
	}
}
