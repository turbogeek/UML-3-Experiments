package UML3StructureRequirements {
	doc
	/*
	STR: requirements on the structural constructs of SysUML: classes, interfaces and their realization,
	attributes and operations, associations and ownership, generalization sets, templates, packages and
	visibility, instances and class constraints.

	Contents:
	- Classifiers: classConcept, activeClassConcept, interfaceRealization, dataTypeConcept.
	- Features: attributeProperties, operationFeatures, leafElements.
	- Relationships: associationEnds, associationClassesAreClasses, ownershipAndAggregation,
	  generalizationSets.
	- Generic types and organization: templateBinding, namespacesAndVisibility.
	- Instances and constraints: instanceSnapshots, classConstraints.
	- UseCases: how developers, architects and reviewers use the structural constructs.
	- Realization: the library elements that realize the done and tbc requirements.
	References: docs/REQUIREMENTS-GUIDE.md; docs/DESIGN.md; UML 2.5.1 Class; KerML 7.4.3; KerML 7.4.5; SysML 7.13.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;

	requirement <'UML3-STR-001'> classConcept {
		doc
		/*
		SysUML shall provide a class concept whose instances are objects with identity that own attributes and
		operations. The concept shall apply to item and part definitions and usages, and an abstract class
		shall be declared with the native abstract modifier.
		Verified by: tools/run_tests.py suite cameo; tools/run_tests.py suite traceability; E05.
		*/
		@Rationale { text = "Classes are the center of object-oriented analysis and design; a definition that really specializes the SysUML class can be queried, viewed and checked as a class."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-STR-002'> activeClassConcept {
		doc
		/*
		SysUML shall provide an active class concept for objects that have their own thread of control and
		lifecycle, such as services, schedulers and actors. Every active class shall also be a class, and the
		concept shall apply to part definitions and usages.
		Verified by: library/UML3Core.sysml; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Active objects run concurrently with their callers, so design reviews, code generation and deployment treat them differently from passive objects."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-STR-003'> interfaceRealization {
		doc
		/*
		SysUML shall provide interfaces as contracts of abstract operations and attributes, distinct from the
		SysML v2 interface definitions that connect ports. A class shall realize one or more interfaces by
		specializing them and redefining their operations, and SysUML tooling shall report a concrete class that
		leaves an operation of a realized interface abstract.
		Verified by: tools/run_tests.py suite rules-tests; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Programming to interfaces is the basis of API and component design, and an operation that a realizing class leaves unimplemented is a defect that should be found in the model rather than by a compiler."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-STR-004'> attributeProperties {
		doc
		/*
		SysUML shall express the attributes of a class as attribute usages typed by value types, with
		multiplicity, ordering, uniqueness, a default value and read-only status. SysUML shall mark class-scoped
		(static) attributes and attributes that take part in the identity of instances, and shall document when
		a separate attribute definition is preferred to an attribute usage.
		Verified by: tools/run_tests.py suite cameo; tools/run_tests.py suite idl-import; tools/run_tests.py suite traceability.
		*/
		@Rationale { text = "Attributes carry most of the information of a class model; static and identity markers are needed by code generators and persistence mappings, and guidance on attribute definitions avoids one-use value types (decision 2026-09-16)."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-STR-005'> operationFeatures {
		doc
		/*
		SysUML shall provide operations as behavioral features of classes and interfaces, with in, out, inout and
		return parameters, which specializations can redefine. SysUML shall mark queries, which return a result
		without side effects, and constructors, which create and initialize an instance of the owning class.
		Verified by: tools/run_tests.py suite cameo; tools/run_tests.py suite idl-import; examples/01-OnlineStoreDomain.sysml.
		*/
		@Rationale { text = "Operations define the services of a class and are the unit of API design and code generation; queries and constructors are generated and called differently from other operations."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-STR-006'> leafElements {
		doc
		/*
		SysUML shall provide a marker for classifiers that may not be specialized and for features that may not
		be redefined (UML isLeaf). SysUML tooling shall report a specialization of a marked classifier and a
		redefinition of a marked feature.
		*/
		@Rationale { text = "A final marker that nothing enforces is only a comment, while frameworks and generated code rely on final classes and methods not being specialized or overridden."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-STR-007'> associationEnds {
		doc
		/*
		SysUML shall provide associations between classifiers with one end for each participant. Each end shall
		state the participating type, the end multiplicity and whether the end is navigable from the opposite
		end.
		Verified by: tools/run_tests.py suite cameo; E04; examples/01-OnlineStoreDomain.sysml.
		*/
		@Rationale { text = "End multiplicities and navigability decide cardinality rules, reference fields in generated code and foreign keys in data models."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-STR-008'> associationClassesAreClasses {
		doc
		/*
		An association that owns attributes or operations (an association class) shall be both an association
		and a class, so that the queries, views and rules that apply to classes also apply to it.
		*/
		@Rationale { text = "In UML an association class is both an association and a class, and generators turn it into a class; an association that is not also a SysUML class is missed by class queries and class diagrams."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-STR-009'> ownershipAndAggregation {
		doc
		/*
		SysUML shall distinguish composite ownership, in which the whole owns the lifetime of its parts, from
		references without ownership, both for features and for associations. SysUML shall also provide shared
		aggregation as a kind of association.
		Verified by: tools/run_tests.py suite cameo; examples/01-OnlineStoreDomain.sysml.
		*/
		@Rationale { text = "Ownership determines lifetime, cascading deletion, serialization boundaries and memory management in generated code."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-STR-010'> generalizationSets {
		doc
		/*
		SysUML shall express generalization, including multiple generalization, with native specialization.
		SysUML shall group the specializations of a classifier into named generalization sets that state whether
		the set is covering and whether it is disjoint.
		Verified by: examples/01-OnlineStoreDomain.sysml; tools/run_tests.py suite traceability.
		*/
		@Rationale { text = "Generalization sets record analysis decisions such as mutually exclusive subtypes, which drive inheritance mapping in data models and exhaustive case handling in code."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-STR-011'> templateBinding {
		doc
		/*
		SysUML shall provide templates, classifiers whose template parameters are abstract features, and shall
		bind a template by a specialization that redefines its template parameters with concrete types.
		Verified by: tools/run_tests.py suite cameo; examples/01-OnlineStoreDomain.sysml.
		*/
		@Rationale { text = "Generic repositories, containers and services are common in software designs and map to generics and templates in target languages."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-STR-012'> namespacesAndVisibility {
		doc
		/*
		SysUML models shall be organized with native packages, namespace and membership imports, and the public,
		protected and private visibility of members. SysUML shall not adopt UML package merge, and its
		traceability shall record that package merge and package visibility have no SysML v2 counterpart.
		Verified by: tools/run_tests.py suite names-positive; tools/run_tests.py suite negative; tools/run_tests.py suite traceability.
		*/
		@Rationale { text = "Packages, imports and visibility control what each part of a large model can see and depend on, and native constructs keep SysUML models navigable in every SysML v2 tool."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-STR-013'> instanceSnapshots {
		doc
		/*
		SysUML shall express instances of classes, with the values of their attributes and their links to other
		instances at chosen points in time, using native individuals, snapshots and feature values instead of
		a SysUML instance construct.
		Verified by: examples/06-OnlineStoreBehavior.sysml; tools/run_tests.py suite cameo; tools/run_tests.py suite traceability.
		*/
		@Rationale { text = "Object diagrams and example data explain and validate class models, and SysML v2 individuals add lifetimes and snapshots that UML instance specifications lack."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-STR-014'> classConstraints {
		doc
		/*
		SysUML shall express the invariants of a class as asserted constraints owned by the class, which every
		instance satisfies, and derived attributes as attributes whose values are computed by an expression.
		Verified by: traceability/uml2-to-uml3.json; tools/run_tests.py suite traceability.
		*/
		@Rationale { text = "Invariants and derivation rules state business rules precisely enough for review, test generation and runtime checks, with KerML expressions in the place of OCL."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-STR-015'> dataTypeConcept {
		doc
		/*
		SysUML shall provide a data type concept, distinct from the class concept, whose instances are values
		without identity: two values of a data type are equal when their attribute values are equal. The concept
		shall apply to attribute definitions and usages only, so that the content of messages, data streams and
		stored records can be modeled apart from objects that have identity and behavior.
		Verified by: tools/run_tests.py suite traceability; tools/run_tests.py suite cameo-probes; E05; E15.
		*/
		@Rationale { text = "UML separates classes, whose instances have identity, from data types, whose instances are values, and software keeps the same split between classes and structs or records. Values can be copied, compared and serialized into messages and streams without deciding how identity and references are encoded, so a design has to say which of the two it means."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	package UseCases {
		doc
		/*
		UseCases: how developers, architects and reviewers use the structural constructs of SysUML.

		Contents:
		- DesignClassStructure: a software developer designs the classes of a component in detail.
		- AnalyzeDomainClasses: an architect and a product owner model the concepts and rules of a domain.
		- ExplainDesignWithInstances: a developer explains a class design to a reviewer with example instances.
		- ReviewClassDesign: a reviewer has tools check a class model before it is used.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def DesignClassStructure {
			doc
			/*
			A software developer designs the classes of a software component in detail: classes and active
			classes, data types, interfaces and their realizations, attributes, operations, associations and
			ownership, templates and packages, ready for review and implementation.
			*/
			subject environment : UML3Environment;
			actor developer : SoftwareDeveloper;
			objective {
				doc /* The class model is precise enough to implement or generate the component without guessing. */
			}
		}

		use case def AnalyzeDomainClasses {
			doc
			/*
			A software architect models the concepts of a business domain together with the product owner:
			classes, associations with their multiplicities, association classes, ownership, generalization
			sets and the invariants that state the business rules.
			*/
			subject environment : UML3Environment;
			actor architect : SoftwareArchitect;
			actor owner : ProductOwner;
			objective {
				doc /* The domain model states concepts, relationships and rules that the product owner confirms. */
			}
		}

		use case def ExplainDesignWithInstances {
			doc
			/*
			A software developer explains a class design with example instances: individuals of the classes,
			their attribute values and links at chosen points in time, consistent with the class invariants.
			*/
			subject environment : UML3Environment;
			actor developer : SoftwareDeveloper;
			actor reviewer : Reviewer;
			objective {
				doc /* The reviewer understands and challenges the design through concrete, consistent examples. */
			}
		}

		use case def ReviewClassDesign {
			doc
			/*
			A reviewer has tools check a class model before it is used: interface realizations are complete,
			final classifiers are not specialized, generalization sets are consistent, association classes are
			treated as classes and keywords are applied to the right kinds of elements.
			*/
			subject environment : UML3Environment;
			actor reviewer : Reviewer;
			objective {
				doc /* Structural defects are reported by tools instead of being found in generated code or at run time. */
			}
		}

		#traces dependency from DesignClassStructure to 'UML3-STR-001', 'UML3-STR-002', 'UML3-STR-003', 'UML3-STR-004',
			'UML3-STR-005', 'UML3-STR-007', 'UML3-STR-009', 'UML3-STR-011', 'UML3-STR-012', 'UML3-STR-015',
			UML3CoreRequirements::'UML3-CORE-003';
		#traces dependency from AnalyzeDomainClasses to 'UML3-STR-001', 'UML3-STR-007', 'UML3-STR-008', 'UML3-STR-009',
			'UML3-STR-010', 'UML3-STR-014';
		#traces dependency from ExplainDesignWithInstances to 'UML3-STR-004', 'UML3-STR-013', 'UML3-STR-014';
		#traces dependency from ReviewClassDesign to 'UML3-STR-003', 'UML3-STR-006', 'UML3-STR-008', 'UML3-STR-010',
			UML3CoreRequirements::'UML3-CORE-008';
	}

	package Realization {
		doc
		/*
		Realization: the SysUML and SysML v2 library elements that realize the done and tbc STR requirements.

		Contents:
		- #realizes dependencies from library elements to STR requirements.
		*/
		#realizes dependency from UML3Core::Class to 'UML3-STR-001';
		#realizes dependency from UML3Core::classType to 'UML3-STR-001';
		#realizes dependency from UML3Core::ActiveClass to 'UML3-STR-002';
		#realizes dependency from UML3Core::activeClass to 'UML3-STR-002';
		#realizes dependency from UML3Core::InterfaceType to 'UML3-STR-003';
		#realizes dependency from UML3Core::interfaceType to 'UML3-STR-003';
		#realizes dependency from SysML::AttributeUsage to 'UML3-STR-004';
		#realizes dependency from UML3Core::static to 'UML3-STR-004';
		#realizes dependency from UML3Core::id to 'UML3-STR-004';
		#realizes dependency from UML3Core::operation to 'UML3-STR-005';
		#realizes dependency from UML3Core::query to 'UML3-STR-005';
		#realizes dependency from UML3Core::constructor to 'UML3-STR-005';
		#realizes dependency from UML3Core::Association to 'UML3-STR-007';
		#realizes dependency from UML3Core::association to 'UML3-STR-007';
		#realizes dependency from UML3Core::navigable to 'UML3-STR-007';
		#realizes dependency from UML3Core::Composition to 'UML3-STR-009';
		#realizes dependency from UML3Core::Aggregation to 'UML3-STR-009';
		#realizes dependency from UML3Core::AggregationKind to 'UML3-STR-009';
		#realizes dependency from UML3Core::GeneralizationSet to 'UML3-STR-010';
		#realizes dependency from UML3Core::InGeneralizationSet to 'UML3-STR-010';
		#realizes dependency from UML3Core::template to 'UML3-STR-011';
		#realizes dependency from UML3Core::templateParameter to 'UML3-STR-011';
		#realizes dependency from SysML::Package to 'UML3-STR-012';
		#realizes dependency from SysML::VisibilityKind to 'UML3-STR-012';
		#realizes dependency from SysML::OccurrenceDefinition to 'UML3-STR-013';
		#realizes dependency from SysML::FeatureValue to 'UML3-STR-013';
		#realizes dependency from SysML::AssertConstraintUsage to 'UML3-STR-014';
		#realizes dependency from UML3Core::DataType to 'UML3-STR-015';
		#realizes dependency from UML3Core::dataType to 'UML3-STR-015';
		#realizes dependency from UML3Core::DataTypeKind to 'UML3-STR-015';
	}
}
