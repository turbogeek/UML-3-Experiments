package UML3DevOpsRequirements {
	doc
	/*
	OPS: requirements on using UML3 models in delivery and operations: pipelines, artifact provenance,
	environments and configuration, infrastructure as code, release versioning, observability, service level
	objectives, runbooks, rollout strategies and automated model checks in pipelines.

	Contents:
	- Delivery: deliveryPipelines, artifactProvenance, releaseVersioning, headlessModelChecks.
	- Environments: deploymentEnvironments, configurationParameters, infrastructureAsCode, rolloutStrategies.
	- Operations: observabilitySpecification, serviceLevelObjectives, operationalRunbooks.
	- UseCases: how DevOps engineers, architects and product owners use these capabilities.
	- Realization: the library elements that realize OPS requirements (none yet).
	Deployment topology (nodes, artifacts, containers) is an ARCH requirement; secrets are SEC requirements.
	References: docs/REQUIREMENTS-GUIDE.md; README.md; SysML 7.15; SysML 7.17; SysML 7.21.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;
	private import UML3Components::*;

	requirement <'UML3-OPS-001'> deliveryPipelines {
		doc
		/*
		UML3 shall let a model describe a delivery pipeline as stages and jobs with their triggers, the artifacts
		each job consumes and produces, the quality gates between stages and the environments it deploys to, and
		shall link each pipeline to the components it builds.
		*/
		@Rationale { text = "Pipelines decide how model and code reach production; whether UML3 models pipelines with native actions or only links model elements to pipeline-as-code files is still to be decided."; }
		@StatusInfo { status = StatusKind::tbd; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-OPS-002'> artifactProvenance {
		doc
		/*
		An artifact shall be able to record the components it manifests, the source revision and model version it
		was built from, the build that produced it and its content digest, so that a deployed artifact can be traced
		back to model elements and source.
		*/
		@Rationale { text = "Supply chain security and incident analysis need to know exactly what runs where; artifacts carry only a file name and a version today."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-OPS-003'> deploymentEnvironments {
		doc
		/*
		UML3 shall let a model define deployment environments (for example development, test, staging and
		production) and state for each environment the deployment topology and configuration that differ from a
		shared architecture, without copying the architecture for each environment.
		*/
		@Rationale { text = "Environments differ in size, topology and configuration but must run the same architecture; copying the model per environment lets the copies drift apart."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-OPS-004'> configurationParameters {
		doc
		/*
		Components shall be able to declare their configuration parameters with type, default value, allowed values
		and whether the parameter is a secret, and environments shall bind values to them. UML3 tooling shall report
		a required parameter without a value in an environment and a value bound to an undeclared parameter.
		*/
		@Rationale { text = "Misconfiguration is a leading cause of failed deployments; declared and checked parameters find it before deployment."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-OPS-005'> infrastructureAsCode {
		doc
		/*
		UML3 shall define how nodes, execution environments, containers and deployments correspond to
		infrastructure-as-code definitions (for example Kubernetes manifests, Helm charts or Terraform modules), so
		that such definitions can be generated from the model or linked to it, and differences between the model
		and linked definitions can be reported.
		*/
		@Rationale { text = "Infrastructure is already code; a deployment model that is neither the source of that code nor checked against it becomes documentation that drifts."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-OPS-006'> releaseVersioning {
		doc
		/*
		Models and generated artifacts shall carry versions, and a release shall record which model version, UML3
		library versions and generator versions produced which artifact versions.
		*/
		@Rationale { text = "A release must be reproducible from its model; without recorded versions nobody can tell which model a running artifact was generated from."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-OPS-007'> observabilitySpecification {
		doc
		/*
		Components and services shall be able to specify the telemetry they emit: metrics with name, type and unit,
		log events with level and structured fields, and trace spans with the context they propagate across calls
		and messages.
		*/
		@Rationale { text = "Operability has to be designed; telemetry specified in the model can be generated, checked in implementations and used for dashboards and alerts."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-OPS-008'> serviceLevelObjectives {
		doc
		/*
		UML3 shall let a service declare service level indicators with the telemetry they are computed from, and
		service level objectives with target, time window and error budget, each traceable to the quality attribute
		requirement it makes operational.
		*/
		@Rationale { text = "Service level objectives turn quality attribute requirements into measurable operational targets that decide when reliability work takes priority."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
	}

	requirement <'UML3-OPS-009'> operationalRunbooks {
		doc
		/*
		UML3 shall let components, alerts and service level objectives be linked to the operational procedures that
		apply to them, at least startup, shutdown, scaling, failover, backup, restore and incident response.
		*/
		@Rationale { text = "Operators need the right procedure for the failing element at once; links from the model make missing procedures visible before an incident."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-OPS-010'> headlessModelChecks {
		doc
		/*
		UML3 model checks shall run without a graphical modeling tool, shall return an exit status that distinguishes
		passed checks, findings and tool errors, and shall write machine-readable reports, so that a delivery
		pipeline can gate on the model.
		Verified by: tools/run_tests.py; tools/run_tests.py suite negative; tools/run_tests.py suite rules-tests; tools/run_tests.py suite requirements.
		*/
		@Rationale { text = "Models that are not checked on every change degrade; the local checkers already work this way, but no delivery pipeline runs them yet and the CATIA Magic checks need a running tool."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-OPS-011'> rolloutStrategies {
		doc
		/*
		A deployment shall be able to state its rollout strategy (for example rolling, blue-green or canary), the
		health checks that gate the rollout and the conditions that trigger a rollback.
		*/
		@Rationale { text = "The rollout strategy decides the capacity needed and the impact of a failed release, so it belongs to the deployment design."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	package UseCases {
		doc
		/*
		UseCases: how DevOps engineers, software architects and product owners use UML3 in delivery and operations.

		Contents:
		- AutomateModelDrivenDelivery: a DevOps engineer builds, checks and releases software from the model.
		- ProvisionDeploymentEnvironments: a DevOps engineer and an architect set up environments from the model.
		- OperateModeledServices: a DevOps engineer and a product owner run services against agreed objectives.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def AutomateModelDrivenDelivery {
			doc
			/*
			A DevOps engineer sets up a pipeline that checks the model on every change, generates and builds the
			artifacts, records their provenance and versions, and releases them.
			*/
			subject environment : UML3Environment;
			actor devOps : DevOpsEngineer;
			objective {
				doc /* Every released artifact passed the model checks and can be traced to its model, library and source versions. */
			}
		}

		use case def ProvisionDeploymentEnvironments {
			doc
			/*
			A DevOps engineer and a software architect define the environments of a system, bind configuration and
			secrets per environment, generate or link the infrastructure definitions, and choose rollout strategies.
			*/
			subject environment : UML3Environment;
			actor devOps : DevOpsEngineer;
			actor architect : SoftwareArchitect;
			objective {
				doc /* Each environment runs the modeled architecture with complete, checked configuration. */
			}
		}

		use case def OperateModeledServices {
			doc
			/*
			A DevOps engineer specifies the telemetry of services, agrees service level objectives with the product
			owner and links alerts and objectives to runbooks.
			*/
			subject environment : UML3Environment;
			actor devOps : DevOpsEngineer;
			actor productOwner : ProductOwner;
			objective {
				doc /* Services are observable, their objectives are measured, and every alert leads to a procedure. */
			}
		}

		#traces dependency from AutomateModelDrivenDelivery to 'UML3-OPS-001', 'UML3-OPS-002', 'UML3-OPS-006',
			'UML3-OPS-010', UML3CoreRequirements::'UML3-CORE-012';
		#traces dependency from ProvisionDeploymentEnvironments to 'UML3-OPS-003', 'UML3-OPS-004', 'UML3-OPS-005',
			'UML3-OPS-011', UML3ArchitectureRequirements::'UML3-ARCH-011', UML3ArchitectureRequirements::'UML3-ARCH-013',
			UML3SecurityRequirements::'UML3-SEC-010';
		#traces dependency from OperateModeledServices to 'UML3-OPS-007', 'UML3-OPS-008', 'UML3-OPS-009',
			UML3ArchitectureRequirements::'UML3-ARCH-014';
	}

	package Realization {
		doc
		/*
		Realization: the library elements that realize OPS requirements.

		Contents:
		- No #realizes dependencies yet: no OPS requirement is done, and headlessModelChecks is realized by the
		  checker tools in tools/, which are not model elements.
		*/
	}
}
