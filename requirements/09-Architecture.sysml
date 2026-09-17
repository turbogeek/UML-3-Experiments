package UML3ArchitectureRequirements {
	doc
	/*
	ARCH: requirements on modeling software architecture and deployment with UML3: components and services,
	ports and interface contracts, connectors, layers, boundaries and styles, architecture decisions, technology
	choices, deployment topology, allocation of software to nodes, and quality attributes of components.

	Contents:
	- Components and wiring: componentKinds, portContracts, assemblyAndDelegationConnectors,
	  unconnectedRequiredPorts, connectorContractConformance.
	- Organization and rationale: layersAndBoundaries, architectureStyles, architectureDecisions, technologyTags.
	- Deployment: deploymentTopology, deploymentAndManifestation, allocationConsistency,
	  containerAndCloudDeployment.
	- Qualities: qualityAttributeRequirements.
	- UseCases: how architects and reviewers use these capabilities.
	- Realization: the library elements that realize the done and tbc requirements.
	Pipelines, environments and operations are OPS requirements; security of the architecture is SEC.
	References: docs/REQUIREMENTS-GUIDE.md; docs/DESIGN.md; UML 2.5.1 Component; UML 2.5.1 Deployment;
	SysML 7.12; SysML 7.13; SysML 7.15; SysML 7.21.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;
	private import UML3Components::*;

	requirement <'UML3-ARCH-001'> componentKinds {
		doc
		/*
		UML3 shall provide components, subsystems and services as encapsulated, replaceable units whose behavior is
		reachable only through their ports. Marking a definition as a component, subsystem or service shall make it
		specialize the corresponding library base, so that tools can query all components of a model.
		Verified by: tests/cameo/implied-specializations.json; tools/run_tests.py suite cameo; tools/run_tests.py suite traceability.
		*/
		@Rationale { text = "Components are the primary unit of software architecture in UML 2.x and in current practice; SysML v2 parts have no notion of a replaceable software unit."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-ARCH-002'> portContracts {
		doc
		/*
		A component port shall provide or require an interface contract. A port definition shall name the interface
		type it exposes, a provided port shall be typed by that port definition and a required port by its conjugate.
		UML3 tooling shall report a provided port that is conjugated and a required port that is not.
		Verified by: tests/rules/r07-port-conjugation.sysml; tools/run_tests.py suite rules-tests; tests/cameo/implied-specializations.json; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Provided and required interfaces are how components are composed and substituted; conjugation gives them a native SysML v2 meaning instead of a label."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-ARCH-003'> assemblyAndDelegationConnectors {
		doc
		/*
		UML3 shall distinguish assembly connectors, which connect a required port of one part to a provided port of
		another, from delegation connectors, which connect a port of a component to a port of one of its internal
		parts, and tools shall be able to query each kind.
		Verified by: examples/02-OnlineStoreArchitecture.sysml; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Assembly and delegation have different semantics for substitution and encapsulation; the example exercises assembly only and no test observes the delegation keyword."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-ARCH-004'> unconnectedRequiredPorts {
		doc
		/*
		UML3 tooling shall report a required port of a part that is not connected within the definition that owns
		the part.
		Verified by: tests/rules/r08-required-port-unconnected.sysml; tools/run_tests.py suite rules-tests; tools/run_tests.py suite rules-examples.
		*/
		@Rationale { text = "An unconnected required port is a dependency the assembled system does not satisfy, which usually shows up only at integration time."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-ARCH-005'> connectorContractConformance {
		doc
		/*
		UML3 tooling shall report an assembly connector whose ends are not one required and one provided port, or
		whose provided contract does not conform to the required contract, and a delegation connector that connects
		ports of different direction or incompatible contracts.
		*/
		@Rationale { text = "UML 2.x constrains connector ends to compatible interfaces; without the check a model can wire components that cannot work together and still validate."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-ARCH-006'> layersAndBoundaries {
		doc
		/*
		UML3 shall let a package or component be declared an architectural layer with a level, and shall let an
		element be marked as a boundary element (adapter, gateway or facade) through which other layers or systems
		reach it.
		Verified by: examples/02-OnlineStoreArchitecture.sysml; tests/cameo/display-expectations.json; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Layers and boundaries are the most common way to organize software; the example and its keyword labels are exercised, but no test observes the boundary set or the layer values."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-ARCH-007'> architectureStyles {
		doc
		/*
		UML3 shall let a system, subsystem or package declare the architecture styles it follows (at least layered,
		hexagonal, microservices, event-driven, client-server and pipes and filters) independently of layering, and
		shall define for each style constraints that tooling can check, for example no dependency from a lower layer
		to a higher layer and no access to a hexagon core except through its boundary elements.
		*/
		@Rationale { text = "A declared style is only useful when violations can be found; today the style is an attribute of the layer metadata, so a non-layered style can only be stated on a layer."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-ARCH-008'> architectureDecisions {
		doc
		/*
		UML3 shall provide architecture decision records as model elements with context, decision, status (proposed,
		accepted, deprecated, superseded), consequences and considered alternatives. A decision shall be linkable to
		the model elements it affects and to the decision that supersedes it.
		*/
		@Rationale { text = "Architecture descriptions need their rationale; decisions kept in separate documents drift away from the elements they justify."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-ARCH-009'> technologyTags {
		doc
		/*
		Components, services, brokers, nodes, execution environments and artifacts shall be able to state the
		implementation technology chosen for them and its version.
		Verified by: examples/02-OnlineStoreArchitecture.sysml; examples/03-OnlineStoreMessaging.sysml; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Technology choices drive generation, deployment and risk analysis; the values load and validate in the examples, but no check or generator reads them yet."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-ARCH-010'> deploymentTopology {
		doc
		/*
		UML3 shall provide nodes, devices, execution environments, artifacts and communication paths between nodes,
		so that a model can describe the topology on which software runs, and tools shall be able to select each
		kind for deployment views.
		Verified by: tests/cameo/view-predictions.json; tools/run_tests.py suite cameo; tools/run_tests.py suite traceability.
		*/
		@Rationale { text = "SysML v2 has parts and allocations but no software deployment vocabulary; UML 2.x deployment concepts are widely understood by software engineers."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-ARCH-011'> deploymentAndManifestation {
		doc
		/*
		A model shall be able to state that an artifact is deployed to a node and that an artifact manifests a
		component, using SysML v2 allocations marked as deployments and manifestations.
		Verified by: examples/02-OnlineStoreArchitecture.sysml; tools/run_tests.py suite traceability; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Deployment and manifestation connect the logical architecture to the runtime; the example loads, but no test observes that the allocations join the deployment and manifestation sets."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-ARCH-012'> allocationConsistency {
		doc
		/*
		UML3 tooling shall report a deployment whose source is not an artifact or component or whose target is not a
		node, and a manifestation whose source is not a component or whose target is not an artifact. Tooling shall
		derive, for each component, the nodes it runs on through the artifacts that manifest it, and shall report a
		component of a deployed system that runs on no node.
		*/
		@Rationale { text = "UML 2.x constrains deployment targets and deployed artifacts; UML3 uses general allocations, so these constraints must be restored by rules for deployment views and analyses to be trustworthy."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-ARCH-013'> containerAndCloudDeployment {
		doc
		/*
		UML3 shall provide container images, container instances, orchestrated workloads with replica counts and
		scaling limits, and managed cloud services (for example serverless functions, managed databases, load
		balancers and API gateways), and shall let a deployment state its region and availability zone.
		*/
		@Rationale { text = "Most services now run in containers or as managed cloud services; execution environments with technology tags describe them only informally and cannot drive infrastructure generation."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-ARCH-014'> qualityAttributeRequirements {
		doc
		/*
		UML3 shall let quality attributes of components, services, connectors and deployments (at least latency,
		throughput, availability, scalability, recovery time and recovery point) be stated as native SysML v2
		requirements with measurable attributes and satisfied by those elements, using a UML3 library of standard
		quality attribute requirement definitions.
		*/
		@Rationale { text = "Architecture is driven by quality attributes; stating them as measurable requirements on the elements that must meet them makes trade-offs traceable and checkable."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
	}

	package UseCases {
		doc
		/*
		UseCases: how software architects, DevOps engineers and reviewers use UML3 for architecture and deployment.

		Contents:
		- DesignComponentArchitecture: an architect structures a system into components, contracts and layers.
		- PlanSoftwareDeployment: an architect and a DevOps engineer decide where the software runs.
		- ReviewArchitectureConsistency: a reviewer checks wiring, styles, decisions and qualities.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def DesignComponentArchitecture {
			doc
			/*
			A software architect decomposes a system into components and services, defines the contracts their
			ports provide and require, wires them with assembly and delegation connectors, organizes them in
			layers with boundary elements, records the style, technologies and decisions, and states the quality
			attributes each component has to meet.
			*/
			subject environment : UML3Environment;
			actor architect : SoftwareArchitect;
			objective {
				doc /* The architecture is a queryable model whose structure, contracts, decisions and qualities are explicit. */
			}
		}

		use case def PlanSoftwareDeployment {
			doc
			/*
			A software architect and a DevOps engineer describe the nodes, execution environments, containers and
			cloud services of the runtime, state which artifacts manifest which components and where they are
			deployed, and record the technologies involved.
			*/
			subject environment : UML3Environment;
			actor architect : SoftwareArchitect;
			actor devOps : DevOpsEngineer;
			objective {
				doc /* Every component can be traced to the artifacts and nodes it runs on. */
			}
		}

		use case def ReviewArchitectureConsistency {
			doc
			/*
			A reviewer runs the UML3 architecture checks on a model: contract conformance of connectors, unconnected
			required ports, style constraints and deployment allocations, and inspects the decisions and quality
			attribute requirements behind the design.
			*/
			subject environment : UML3Environment;
			actor reviewer : Reviewer;
			actor architect : SoftwareArchitect;
			objective {
				doc /* Inconsistencies are found in the model before they are built, and each finding names the element to fix. */
			}
		}

		#traces dependency from DesignComponentArchitecture to 'UML3-ARCH-001', 'UML3-ARCH-002', 'UML3-ARCH-003',
			'UML3-ARCH-006', 'UML3-ARCH-007', 'UML3-ARCH-008', 'UML3-ARCH-009', 'UML3-ARCH-014';
		#traces dependency from PlanSoftwareDeployment to 'UML3-ARCH-009', 'UML3-ARCH-010', 'UML3-ARCH-011',
			'UML3-ARCH-012', 'UML3-ARCH-013';
		#traces dependency from ReviewArchitectureConsistency to 'UML3-ARCH-004', 'UML3-ARCH-005', 'UML3-ARCH-007',
			'UML3-ARCH-008', 'UML3-ARCH-012', 'UML3-ARCH-014';
	}

	package Realization {
		doc
		/*
		Realization: the library elements that realize the done and tbc ARCH requirements.

		Contents:
		- #realizes dependencies from UML3Components elements to ARCH requirements.
		*/
		#realizes dependency from UML3Components::component to 'UML3-ARCH-001';
		#realizes dependency from UML3Components::subsystem to 'UML3-ARCH-001';
		#realizes dependency from UML3Components::service to 'UML3-ARCH-001';
		#realizes dependency from UML3Components::ServicePort to 'UML3-ARCH-002';
		#realizes dependency from UML3Components::provided to 'UML3-ARCH-002';
		#realizes dependency from UML3Components::required to 'UML3-ARCH-002';
		#realizes dependency from UML3Components::assembly to 'UML3-ARCH-003';
		#realizes dependency from UML3Components::delegation to 'UML3-ARCH-003';
		#realizes dependency from UML3Components::required to 'UML3-ARCH-004';
		#realizes dependency from UML3Components::layer to 'UML3-ARCH-006';
		#realizes dependency from UML3Components::boundary to 'UML3-ARCH-006';
		#realizes dependency from UML3Components::Technology to 'UML3-ARCH-009';
		#realizes dependency from UML3Components::artifact to 'UML3-ARCH-010';
		#realizes dependency from UML3Components::node to 'UML3-ARCH-010';
		#realizes dependency from UML3Components::device to 'UML3-ARCH-010';
		#realizes dependency from UML3Components::executionEnvironment to 'UML3-ARCH-010';
		#realizes dependency from UML3Components::communicationPath to 'UML3-ARCH-010';
		#realizes dependency from UML3Components::deploy to 'UML3-ARCH-011';
		#realizes dependency from UML3Components::manifest to 'UML3-ARCH-011';
	}
}
