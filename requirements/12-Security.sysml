package UML3SecurityRequirements {
	doc
	/*
	SEC: requirements on modeling the security of software with UML3: assets, threats and mitigations, trust
	boundaries, data classification and privacy, authentication and authorization, secrets and keys, secure
	communication, traceability of security to verification, compliance, and secure generation defaults.

	Contents:
	- Threat modeling: securityAssets, threatRecords, threatMitigations, trustBoundaries.
	- Data protection: sensitivityClassification, classificationRules, privacyProcessing.
	- Access control and secrets: authenticationSchemes, authorizationPolicies, secretsAndKeys.
	- Protection of communication: secureCommunication.
	- Assurance: securityVerificationTraceability, complianceMapping, secureGenerationDefaults.
	- UseCases: how security engineers, architects, developers, data modelers and reviewers use these capabilities.
	- Realization: the library elements that realize the tbc requirements.
	Data governance other than classification is a DATA requirement; deployment topology is ARCH.
	References: docs/REQUIREMENTS-GUIDE.md; docs/DESIGN.md; SysML 7.21; SysML 7.24; SysML 7.27.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;
	private import UML3Data::*;

	requirement <'UML3-SEC-001'> securityAssets {
		doc
		/*
		UML3 shall let a model identify the assets to protect (data, components, services, credentials and
		artifacts) and state for each its security objectives for confidentiality, integrity and availability.
		*/
		@Rationale { text = "Threat analysis starts from what is worth protecting; assets and their objectives decide which threats matter."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-SEC-002'> threatRecords {
		doc
		/*
		UML3 shall let a model record threats against assets and against the components, connectors, flows and data
		that expose them, each classified by a stated category scheme (for example STRIDE) and rated for likelihood
		and impact.
		*/
		@Rationale { text = "Threat models kept outside the architecture model go stale as the architecture changes; linking threats to elements keeps the analysis current and reviewable."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-SEC-003'> threatMitigations {
		doc
		/*
		UML3 shall let a model link each threat to the mitigations that address it, or record the acceptance of its
		risk, and link each mitigation to the security controls, requirements or design elements that implement it.
		UML3 tooling shall report threats with neither a mitigation nor an accepted risk, and accepted risks without
		a rationale.
		*/
		@Rationale { text = "A threat model is complete only when every threat is either mitigated by something in the design or consciously accepted."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
	}

	requirement <'UML3-SEC-004'> trustBoundaries {
		doc
		/*
		UML3 shall let an architecture declare trust boundaries that group components, nodes and networks of equal
		trust, and UML3 tooling shall list every connector, flow and communication path that crosses a trust
		boundary.
		*/
		@Rationale { text = "Attacks enter where data crosses from less trusted to more trusted zones; the boundary element marker of layered and hexagonal architectures does not express trust zones."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-SEC-005'> sensitivityClassification {
		doc
		/*
		A data element (an entity, attribute, table, column or message field) shall be able to carry a sensitivity
		classification, for example personal data, payment card data or health data.
		Verified by: examples/04-OnlineStoreDatabase.sysml; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Classification decides which protection data needs; a classification loads and validates in the example, but it is free text and no check reads it."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-SEC-006'> classificationRules {
		doc
		/*
		UML3 shall let a model declare a classification scheme with ordered levels and the protection each level
		requires. UML3 tooling shall derive the classification of messages, channels, tables, artifacts and
		components that store, carry or process classified data, and shall report an element that stores or carries
		classified data without the protection its level requires, such as encryption in transit or at rest.
		*/
		@Rationale { text = "Free-text labels cannot be compared or propagated; sensitive data leaks through the messages, logs and stores that copy it unless classification follows the data."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-SEC-007'> privacyProcessing {
		doc
		/*
		UML3 shall let personal data elements state the purposes they are processed for, the legal basis of the
		processing, the data subject rights that apply (for example access and erasure) and transfers outside their
		jurisdiction.
		*/
		@Rationale { text = "Privacy regulations require records of processing per personal data element; whether UML3 models these jurisdiction-specific concepts itself or links to a privacy management system is still to be decided."; }
		@StatusInfo { status = StatusKind::tbd; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-SEC-008'> authenticationSchemes {
		doc
		/*
		UML3 shall let a model state, for each provided port, API operation, channel and administrative interface,
		how callers are authenticated (for example mutual TLS, OAuth 2.0 or OpenID Connect tokens, or API keys) and
		which identity provider issues their credentials.
		*/
		@Rationale { text = "Authentication is part of every service contract; when it is not in the model, generated API descriptions and reviews miss it."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-SEC-009'> authorizationPolicies {
		doc
		/*
		UML3 shall let a model define roles, permissions and attribute-based access policies, and state the
		permissions required to call each operation, to receive from each channel and to read or change each data
		element. UML3 tooling shall report an operation or channel reachable across a trust boundary without an
		access policy.
		*/
		@Rationale { text = "Broken access control is the most common class of web application vulnerability; policies stated on model elements can be reviewed, generated and checked for gaps."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-SEC-010'> secretsAndKeys {
		doc
		/*
		UML3 shall let a model declare secrets, credentials, certificates and cryptographic keys as elements distinct
		from ordinary configuration, with the store that holds them, their rotation period and the components allowed
		to use them. UML3 tooling shall report a secret whose value is written in the model.
		*/
		@Rationale { text = "Secrets in models, code or configuration files are leaked through version control; the model should say which secret is needed where, never its value."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-SEC-011'> secureCommunication {
		doc
		/*
		Connectors, flows, channels and communication paths shall be able to require encryption in transit with a
		protocol and minimum protocol version, mutual authentication of their endpoints and message integrity
		protection. UML3 tooling shall report a communication that crosses a trust boundary without these
		requirements.
		*/
		@Rationale { text = "Communication paths carry only a free-text protocol today, so the model cannot show whether traffic between trust zones is protected."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-SEC-012'> securityVerificationTraceability {
		doc
		/*
		Security requirements, mitigations and controls shall be traceable to the verification cases that
		demonstrate them (for example security tests, penetration tests, static analysis or reviews), and UML3
		tooling shall report security requirements and mitigations that no verification case verifies.
		*/
		@Rationale { text = "Unverified controls give false assurance; SysML v2 verification cases can carry the evidence once security elements are linked to them."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
	}

	requirement <'UML3-SEC-013'> complianceMapping {
		doc
		/*
		UML3 shall let security requirements and controls be mapped by clause identifier to named standards and
		regulations (for example ISO/IEC 27001, PCI DSS, GDPR, HIPAA or OWASP ASVS), and tools shall report the
		coverage of each mapped standard.
		*/
		@Rationale { text = "Audits ask which controls meet which clauses; clause identifiers can be referenced without reproducing the text of the standards."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
	}

	requirement <'UML3-SEC-014'> secureGenerationDefaults {
		doc
		/*
		Generators that claim UML3 conformance shall produce secure defaults where the model states nothing else:
		deny-by-default authorization, encrypted transport, parameterized database access, input validation derived
		from facets and constraints, and no secret values in generated code or configuration.
		*/
		@Rationale { text = "Generated code is replicated across many services, so an insecure default becomes a systemic vulnerability, while a secure default costs nothing when the model is silent."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	package UseCases {
		doc
		/*
		UseCases: how security engineers work with architects, data modelers, developers and reviewers in UML3.

		Contents:
		- ThreatModelSoftwareArchitecture: a security engineer and an architect analyze threats on the architecture.
		- ProtectClassifiedData: a security engineer and a data modeler classify and protect data.
		- SpecifyAccessControls: a security engineer and a developer specify authentication, authorization and secrets.
		- DemonstrateSecurityCompliance: a security engineer and a reviewer show controls are verified and compliant.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def ThreatModelSoftwareArchitecture {
			doc
			/*
			A security engineer and a software architect identify assets, draw trust boundaries on the architecture,
			record threats against the elements that cross or sit on them, decide mitigations, and require protected
			communication where data crosses a boundary.
			*/
			subject environment : UML3Environment;
			actor securityEngineer : SecurityEngineer;
			actor architect : SoftwareArchitect;
			objective {
				doc /* The threat model lives in the architecture model and shows for every threat how it is handled. */
			}
		}

		use case def ProtectClassifiedData {
			doc
			/*
			A security engineer defines the classification scheme and a data modeler classifies data elements;
			the tools derive where classified data flows and is stored and report missing protection, keys and
			privacy obligations.
			*/
			subject environment : UML3Environment;
			actor securityEngineer : SecurityEngineer;
			actor modeler : DataModeler;
			objective {
				doc /* Every store and carrier of sensitive data is known and protected according to its classification. */
			}
		}

		use case def SpecifyAccessControls {
			doc
			/*
			A security engineer states how callers authenticate and which permissions each operation, channel and
			data element requires, declares the secrets components need, and a software developer generates or
			implements services with secure defaults from that specification.
			*/
			subject environment : UML3Environment;
			actor securityEngineer : SecurityEngineer;
			actor developer : SoftwareDeveloper;
			objective {
				doc /* Access to every exposed operation and channel is specified, reviewable and enforced by default. */
			}
		}

		use case def DemonstrateSecurityCompliance {
			doc
			/*
			A security engineer links controls and mitigations to verification cases and to the clauses of the
			standards that apply, and a reviewer inspects the coverage and the evidence.
			*/
			subject environment : UML3Environment;
			actor securityEngineer : SecurityEngineer;
			actor reviewer : Reviewer;
			objective {
				doc /* Compliance claims are backed by traced controls and passed verification cases. */
			}
		}

		#traces dependency from ThreatModelSoftwareArchitecture to 'UML3-SEC-001', 'UML3-SEC-002', 'UML3-SEC-003',
			'UML3-SEC-004', 'UML3-SEC-011', UML3ArchitectureRequirements::'UML3-ARCH-006';
		#traces dependency from ProtectClassifiedData to 'UML3-SEC-005', 'UML3-SEC-006', 'UML3-SEC-007',
			'UML3-SEC-010', UML3DataModelingRequirements::'UML3-DATA-011';
		#traces dependency from SpecifyAccessControls to 'UML3-SEC-008', 'UML3-SEC-009', 'UML3-SEC-010',
			'UML3-SEC-014', UML3MessagingRequirements::'UML3-MSG-011';
		#traces dependency from DemonstrateSecurityCompliance to 'UML3-SEC-003', 'UML3-SEC-012', 'UML3-SEC-013';
	}

	package Realization {
		doc
		/*
		Realization: the library elements that realize the tbc SEC requirements.

		Contents:
		- #realizes dependencies from UML3Data elements to SEC requirements.
		*/
		#realizes dependency from UML3Data::Sensitivity to 'UML3-SEC-005';
	}
}
