package UML3SysMLInteropRequirements {
	doc
	/*
	SYS: requirements on using UML3 inside SysML v2 system models and with other KerML-based languages: software
	models in the same model as the system, allocation of software to hardware and functions, requirements,
	verification and variability shared by systems and software engineering, access through the Systems
	Modeling API and Services, and coexistence with the SysML v2 standard libraries and with models transformed
	from SysML v1.

	Contents:
	- One model: embeddingInSystemModels, standardLibraryDependenciesOnly, unambiguousLibraryNames,
	  combinedSystemAndSoftwareRoles.
	- Allocation and interfaces: softwareDeploymentToHardware, functionalAllocationToSoftware,
	  softwareHardwareInterfaces.
	- Shared engineering data: sharedRequirementSatisfaction, sharedVerificationCases, apiQueriesByConcept,
	  coSimulationAndAnalysis, sharedVariability.
	- Other languages and legacy models: otherKerMLLanguages, sysmlV1TransformedModels.
	- UseCases: how systems engineers, software architects, test engineers and tool vendors work in one model.
	- Realization: the library elements that realize the done and tbc requirements.
	References: docs/REQUIREMENTS-GUIDE.md; SysML 7.15; SysML 7.21; SysML 7.24; KerML 9.2.16.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;
	private import UML3Components::*;

	requirement <'UML3-SYS-001'> embeddingInSystemModels {
		doc
		/*
		UML3 software model elements shall be usable directly in SysML v2 system models, in the same project and
		namespaces as the hardware, functions and requirements of the system, without conversion, export or a
		separate modeling environment.
		Verified by: tools/run_tests.py suite cameo; examples/02-OnlineStoreArchitecture.sysml.
		*/
		@Rationale { text = "Systems and software engineers work on one product; separate UML and SysML models have to be synchronized by hand and drift apart, which is the integration problem UML3 is meant to remove."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-SYS-002'> standardLibraryDependenciesOnly {
		doc
		/*
		The UML3 libraries shall depend only on the KerML and SysML v2 standard libraries and on each other, so
		that a system model can use them in any conforming SysML v2 implementation without vendor libraries or
		profiles.
		Verified by: tools/run_tests.py suite names-positive; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "System models are shared across organizations and tools, and a vendor dependency in the software libraries would tie the whole system model to one tool."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
	}

	requirement <'UML3-SYS-003'> unambiguousLibraryNames {
		doc
		/*
		Importing the UML3 libraries together with the SysML v2 standard libraries that system models commonly
		import, such as ISQ, SI, Time, Cases and StandardViewDefinitions, shall not make a simple name ambiguous,
		or UML3 shall document for each such name the qualified name to use.
		*/
		@Rationale { text = "A system model that imports quantities, time and views next to UML3 must still resolve its simple names, but DurationValue, Date and TimeOfDay also exist in ISQ and Time, Class, DataType, Association and Relationship in the metaclass names that StandardViewDefinitions re-exports, and Case in Cases."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
	}

	requirement <'UML3-SYS-004'> combinedSystemAndSoftwareRoles {
		doc
		/*
		An element that plays both a system role and a software role, for example a SysML v2 part that is also a
		UML3 #node or #executionEnvironment, shall be able to carry the semantic metadata of both roles with the
		implied specialization of each applied in every conforming tool, or UML3 shall define combined keywords
		for such roles.
		*/
		@Rationale { text = "KerML applies every semantic keyword of an element but CATIA Magic applies only the first one (E02, E03), so whether UML3 relies on stacked keywords or defines combined keywords is still to be decided."; }
		@StatusInfo { status = StatusKind::tbd; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-SYS-005'> softwareDeploymentToHardware {
		doc
		/*
		UML3 shall allow software artifacts and components to be allocated to the hardware parts of a SysML v2
		system model, including parts that carry no UML3 keyword, with native allocation usages that SysML v2
		tools can query and show in allocation views.
		Verified by: examples/02-OnlineStoreArchitecture.sysml; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Where software runs determines the timing, safety, security and cost analyses of a system, so deployment has to be one relationship in the shared model rather than a table in a separate document."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-SYS-006'> functionalAllocationToSoftware {
		doc
		/*
		System functions modeled as SysML v2 actions shall be allocatable to UML3 components, operations and
		state machines with native allocation usages, and UML3 shall define how such allocations are checked for
		completeness.
		*/
		@Rationale { text = "The functional architecture decides which functions software implements; the allocation is the handover from systems to software engineering and has to be checkable in the model."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-SYS-007'> softwareHardwareInterfaces {
		doc
		/*
		UML3 service ports, producer and consumer ports and communication paths shall be connectable to the ports
		and interfaces of SysML v2 system parts with native connections, so that each software contract is bound
		to the system interface that carries it.
		*/
		@Rationale { text = "A message or API contract travels over a physical or logical system interface such as a bus, a network or a radio link, and interface analysis and integration testing need that binding in one model."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-SYS-008'> sharedRequirementSatisfaction {
		doc
		/*
		UML3 design elements shall satisfy SysML v2 requirements with the native satisfy relationship, so that
		systems and software engineering share one set of requirements and SysML v2 tools compute satisfaction
		without UML3-specific relationships.
		*/
		@Rationale { text = "Requirements flow from the system to its software; if software uses its own trace relationships, the coverage reports of the system model cannot see what the software satisfies."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-SYS-009'> sharedVerificationCases {
		doc
		/*
		The verification of UML3 software, including test results and checker runs, shall be expressible as
		native SysML v2 verification cases that verify the same requirements as the system verification and
		record verdicts, so that the verification status of the system includes its software.
		*/
		@Rationale { text = "Certification and program reviews assess the verification of the whole system, and software evidence kept outside the model as text or tool reports cannot be rolled up."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-SYS-010'> apiQueriesByConcept {
		doc
		/*
		UML3 models shall be storable, versioned and queryable through the Systems Modeling API and Services, and
		a query for a UML3 concept, for example all elements that specialize UML3Data::Entity, shall be
		expressible as a standard API query without UML3-specific services.
		*/
		@Rationale { text = "System models are increasingly managed in API-based repositories, and software content is shared with the system only if generic API clients can find it by concept."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-SYS-011'> coSimulationAndAnalysis {
		doc
		/*
		Software properties and behaviors modeled with UML3, such as execution times, memory use, message rates
		and quality of service, shall be usable as inputs of SysML v2 analysis cases and through co-simulation
		interfaces such as the Functional Mock-up Interface, so that system analyses account for the software.
		*/
		@Rationale { text = "Timing, performance and resource budgets of a system depend on its software, so analyses that ignore software properties give wrong results for software-intensive systems."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-SYS-012'> sharedVariability {
		doc
		/*
		UML3 elements shall take part in SysML v2 variability, as variation points and variants, so that
		selecting a system variant also selects the software configuration that belongs to it.
		*/
		@Rationale { text = "Product lines vary hardware and software together, and one variability model avoids system variants that are combined with incompatible software."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-SYS-013'> otherKerMLLanguages {
		doc
		/*
		UML3 concepts shall be usable from KerML-based languages other than SysML v2, either by importing the
		UML3 libraries or through KerML renderings of the libraries that keep the same qualified names and
		semantics.
		*/
		@Rationale { text = "Other KerML-based languages are emerging for specific domains, but the UML3 libraries use SysML v2 definitions such as item, part and port definitions, so whether and how to offer a KerML rendering is still to be decided."; }
		@StatusInfo { status = StatusKind::tbd; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-SYS-014'> sysmlV1TransformedModels {
		doc
		/*
		The UML3 libraries and keywords shall be usable in SysML v2 models produced by the SysML v1 to SysML v2
		transformation, without name clashes or conflicting semantics with the elements that the transformation
		generates.
		*/
		@Rationale { text = "Most existing system models are SysML v1 models, often with UML software parts, that reach SysML v2 through the standard transformation, so UML3 has to work on the result."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	package UseCases {
		doc
		/*
		UseCases: how systems and software engineering use UML3 in one SysML v2 model and tool chain.

		Contents:
		- DevelopSoftwareInSystemModel: a systems engineer and a software architect design system and software together.
		- ShareRequirementsAndVerification: a systems engineer and a test engineer share requirements and verification.
		- IntegrateUML3IntoToolchain: a tool vendor and a language maintainer make UML3 work wherever SysML v2 models live.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def DevelopSoftwareInSystemModel {
			doc
			/*
			A systems engineer and a software architect work in one SysML v2 model: the software architecture is
			modeled with UML3 next to the hardware and functional architecture, system functions are allocated to
			software, software is deployed to hardware parts, and software contracts are bound to system interfaces.
			*/
			subject environment : UML3Environment;
			actor systemsEngineer : SystemsEngineer;
			actor architect : SoftwareArchitect;
			objective {
				doc /* One consistent model in which allocation, deployment, interfaces and variants of system and software can be analyzed. */
			}
		}

		use case def ShareRequirementsAndVerification {
			doc
			/*
			A systems engineer derives software requirements in the system model, the UML3 design satisfies them,
			and a test engineer records the software verification as verification cases that the system
			verification status includes.
			*/
			subject environment : UML3Environment;
			actor systemsEngineer : SystemsEngineer;
			actor tester : TestEngineer;
			objective {
				doc /* Requirement coverage and verification status of the whole system, software included, come from one model. */
			}
		}

		use case def IntegrateUML3IntoToolchain {
			doc
			/*
			A tool vendor and a language maintainer make UML3 available wherever SysML v2 models live: in SysML v2
			tools, in API-based repositories, in other KerML-based languages and in models transformed from SysML v1.
			*/
			subject environment : UML3Environment;
			actor vendor : ToolVendor;
			actor maintainer : LanguageMaintainer;
			objective {
				doc /* UML3 content works with every conforming SysML v2 implementation and repository without name or semantic conflicts. */
			}
		}

		#traces dependency from DevelopSoftwareInSystemModel to 'UML3-SYS-001', 'UML3-SYS-003', 'UML3-SYS-004', 'UML3-SYS-005',
			'UML3-SYS-006', 'UML3-SYS-007', 'UML3-SYS-011', 'UML3-SYS-012', UML3CoreRequirements::'UML3-CORE-004';
		#traces dependency from ShareRequirementsAndVerification to 'UML3-SYS-008', 'UML3-SYS-009', 'UML3-SYS-010';
		#traces dependency from IntegrateUML3IntoToolchain to 'UML3-SYS-002', 'UML3-SYS-003', 'UML3-SYS-010', 'UML3-SYS-013',
			'UML3-SYS-014', UML3CoreRequirements::'UML3-CORE-001', UML3CoreRequirements::'UML3-CORE-003',
			UML3CoreRequirements::'UML3-CORE-013';
	}

	package Realization {
		doc
		/*
		Realization: the library elements that realize the done and tbc SYS requirements.

		Contents:
		- #realizes dependencies from the UML3 libraries and deployment elements to SYS requirements.
		*/
		#realizes dependency from UML3Core to 'UML3-SYS-002';
		#realizes dependency from UML3Types to 'UML3-SYS-002';
		#realizes dependency from UML3Components to 'UML3-SYS-002';
		#realizes dependency from UML3Messaging to 'UML3-SYS-002';
		#realizes dependency from UML3Data to 'UML3-SYS-002';
		#realizes dependency from UML3IDL to 'UML3-SYS-002';
		#realizes dependency from UML3Views to 'UML3-SYS-002';
		#realizes dependency from UML3Components::Deployment to 'UML3-SYS-005';
		#realizes dependency from UML3Components::deploy to 'UML3-SYS-005';
	}
}
