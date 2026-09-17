package UML3ViewRequirements {
	doc
	/*
	VIEW: requirements on UML diagrams and tables as SysML v2 views: the diagram kinds UML3 defines, how a view
	selects its content, tables and matrices, how UML3 keywords, notation and documentation appear, how tools
	render views, and viewpoints for software stakeholders.
	Documents and reports composed of views are in UML3ReportRequirements (RPT).

	Contents:
	- Diagram kinds: diagramKindsAsViews, classAndPackageDiagrams, architectureAndDataDiagrams,
	  behaviorDiagrams, useCaseAndObjectDiagrams.
	- Content: exposeAndFilterContent, libraryElementExclusion.
	- Tables and matrices: elementTables, relationshipMatrices.
	- Presentation: keywordLabels, umlNotation, diagramRendering, documentationNotes.
	- Stakeholders: stakeholderViewpoints.
	- UseCases: how architects, developers, data modelers, integration engineers and tool vendors use views.
	- Realization: the view definitions that realize the done requirements.
	References: docs/DESIGN.md; docs/UML2-to-UML3-Traceability.md; SysML 7.26; E06; E07; E12.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;
	private import UML3Views::*;

	requirement <'UML3-VIEW-001'> diagramKindsAsViews {
		doc
		/*
		Each diagram or table kind that UML3 defines shall be a SysML v2 view definition that specializes a
		standard view definition, so that a diagram in a model is a view usage that only states what it exposes.
		Verified by: tools/run_tests.py suite traceability; tools/run_tests.py suite cameo; examples/05-OnlineStoreViews.sysml.
		*/
		@Rationale { text = "Views are model elements that tools evaluate, query and exchange like any other element; a diagram kind that exists only as a diagram type of one tool is lost in interchange."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VIEW-002'> classAndPackageDiagrams {
		doc
		/*
		UML3 shall provide a view definition for class diagrams, presenting classes, active classes, interfaces,
		data types, signals, exceptions, templates, enumerations, associations and dependencies, and a view
		definition for package diagrams, presenting packages.
		Verified by: tools/run_tests.py suite cameo; tests/cameo/view-predictions.json.
		*/
		@Rationale { text = "Class and package diagrams are the most used UML diagrams in object-oriented analysis and design."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VIEW-003'> architectureAndDataDiagrams {
		doc
		/*
		UML3 shall provide view definitions for component diagrams (components, services, subsystems, their ports
		and connectors, also serving as composite structure diagrams), deployment diagrams (artifacts, nodes,
		devices, execution environments, communication paths, deployments and manifestations),
		entity-relationship diagrams (logical and physical data models) and message schema diagrams (message
		types, channels and brokers).
		Verified by: tools/run_tests.py suite cameo; tests/cameo/view-predictions.json.
		*/
		@Rationale { text = "Software architecture, data and messaging are the design areas UML3 adds to SysML v2, and each is reviewed on a diagram of its own."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VIEW-004'> behaviorDiagrams {
		doc
		/*
		Sequence, activity and state machine diagrams shall be available as view definitions: a UML3 sequence
		diagram that presents an interaction, and the standard SysML v2 action flow and state transition views
		used as-is for activities and state machines.
		Verified by: tools/run_tests.py suite cameo; tools/run_tests.py suite traceability.
		*/
		@Rationale { text = "Behavior is reviewed on diagrams as much as structure; SysML v2 already defines views for action flows and state transitions, so only the sequence diagram needs a UML3 definition."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VIEW-005'> useCaseAndObjectDiagrams {
		doc
		/*
		UML3 shall provide a view definition for use case diagrams, presenting use cases, actors, subjects and
		inclusions, and a view definition for object diagrams, presenting individuals, snapshots and their
		feature values.
		*/
		@Rationale { text = "Use case and object diagrams are UML diagram kinds that UML3 realizes with native elements; without a named view definition every model has to repeat their filters."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VIEW-006'> exposeAndFilterContent {
		doc
		/*
		The content of a UML3 view shall be determined only by SysML v2 expose and filter semantics, with filters
		that test UML3 keyword metadata and SysML v2 metaclasses, so that the content does not depend on
		tool-specific selection rules or on diagram layout.
		Verified by: tools/run_tests.py suite cameo; tests/cameo/view-predictions.json.
		*/
		@Rationale { text = "Content defined by standard semantics is the same in every conforming tool, and a filter on keywords keeps a diagram complete as elements are added to the model."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VIEW-007'> libraryElementExclusion {
		doc
		/*
		A UML3 view shall not present elements of the SysML v2 standard library or of the UML3 libraries that
		reach the view only through the imports of an exposed package.
		Verified by: E06; tools/run_tests.py suite cameo; tests/cameo/view-predictions.json.
		*/
		@Rationale { text = "An expose also exposes what the exposed package imports, so without the exclusion every class diagram would also show library elements such as AggregationKind."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VIEW-008'> elementTables {
		doc
		/*
		UML3 shall provide a table view that lists the classes, interfaces, data types and enumerations of the
		exposed packages, one element per row.
		Verified by: tools/run_tests.py suite cameo; tests/cameo/view-predictions.json.
		*/
		@Rationale { text = "A table is the fastest way to review many classes at once, and SysML v2 grid views with element table renderings support it without extensions."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VIEW-009'> relationshipMatrices {
		doc
		/*
		UML3 shall provide matrix views that present one kind of relationship between two sets of elements, for
		example requirements against the elements that realize them, dependencies between packages, or artifacts
		against the nodes they are deployed to.
		*/
		@Rationale { text = "Matrices show missing and unexpected relationships at a glance, which diagrams with many edges hide."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VIEW-010'> keywordLabels {
		doc
		/*
		A tool shall label each element that a view presents with the UML3 semantic keywords applied to the
		element, in the SysML v2 notation for user-defined keywords.
		Verified by: tools/run_tests.py suite cameo; tests/cameo/display-expectations.json.
		*/
		@Rationale { text = "A keyword is the UML3 counterpart of a stereotype, and readers of a diagram need to see it to know what kind of element they are looking at."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VIEW-011'> umlNotation {
		doc
		/*
		UML3 shall define how UML notation without a SysML v2 graphical counterpart appears on UML3 diagrams,
		including navigable association ends, shared aggregation, static features and the values of plain
		metadata such as dependency keywords and facets, either as UML symbols or as keyword labels.
		*/
		@Rationale { text = "UML readers expect arrows, diamonds and underlines; if each tool chooses its own presentation, the same UML3 diagram reads differently in different tools."; }
		@StatusInfo { status = StatusKind::tbd; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-VIEW-012'> diagramRendering {
		doc
		/*
		A tool that supports UML3 shall create, open and update the diagram or table of a view usage from the
		content that the view selects, without requiring stored layout. Stored layout shall not change which
		elements a view presents.
		*/
		@Rationale { text = "A view that a tool can evaluate but not draw does not replace a UML diagram, and layout that changes content would make diagrams disagree with their views."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-VIEW-013'> documentationNotes {
		doc
		/*
		A diagram shall be able to present the documentation of an element and each named comment about the
		element as notes attached to it, and a compact presentation shall show only the first sentence of the
		documentation.
		*/
		@Rationale { text = "UML3 documentation is model content so that it can be read where the element is shown, and its first sentence is written to stand alone for that purpose."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-VIEW-014'> stakeholderViewpoints {
		doc
		/*
		UML3 shall define viewpoints that frame the concerns of software stakeholders, for example structure for
		developers, deployment for operations, data for data modelers and message contracts for integration
		engineers, and each UML3 view definition shall state the viewpoints it satisfies.
		*/
		@Rationale { text = "Viewpoints tie each diagram kind to the stakeholder questions it answers, so that views nobody needs and concerns no view answers can be found."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	package UseCases {
		doc
		/*
		UseCases: how architects, developers, data modelers, integration engineers and tool vendors use views.

		Contents:
		- CommunicateDesignWithDiagrams: an architect presents a design in UML diagrams that developers read.
		- ReviewDataAndMessageContracts: a data modeler and an integration engineer review data and message
		  designs in diagrams, tables and matrices.
		- PresentUML3ViewsInTool: a tool vendor evaluates, draws and labels UML3 views.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def CommunicateDesignWithDiagrams {
			doc
			/*
			A software architect exposes the packages of a design in class, package, component, deployment,
			sequence, activity, state machine, use case and object diagrams, and a developer reads them with their
			keywords, UML notation and documentation notes.
			*/
			subject environment : UML3Environment;
			actor architect : SoftwareArchitect;
			actor developer : SoftwareDeveloper;
			objective {
				doc /* Each diagram shows exactly the design elements of its kind, presented so that a UML reader understands them. */
			}
		}

		use case def ReviewDataAndMessageContracts {
			doc
			/*
			A data modeler and an integration engineer review logical and physical data models and message
			contracts in entity-relationship and message schema diagrams, class tables and relationship matrices.
			*/
			subject environment : UML3Environment;
			actor dataModeler : DataModeler;
			actor integrator : IntegrationEngineer;
			objective {
				doc /* Data and message designs can be reviewed completely and without library elements, as diagrams, tables and matrices. */
			}
		}

		use case def PresentUML3ViewsInTool {
			doc
			/*
			A tool vendor implements UML3 views in a SysML v2 tool: evaluates their content, draws their diagrams
			and tables, labels keywords, presents UML notation and documentation, and offers viewpoints to
			stakeholders.
			*/
			subject environment : UML3Environment;
			actor vendor : ToolVendor;
			objective {
				doc /* The tool presents each UML3 view with the same content as every other conforming tool. */
			}
		}

		#traces dependency from CommunicateDesignWithDiagrams to 'UML3-VIEW-001', 'UML3-VIEW-002', 'UML3-VIEW-003',
			'UML3-VIEW-004', 'UML3-VIEW-005', 'UML3-VIEW-010', 'UML3-VIEW-011', 'UML3-VIEW-013',
			UML3CoreRequirements::'UML3-CORE-006';
		#traces dependency from ReviewDataAndMessageContracts to 'UML3-VIEW-003', 'UML3-VIEW-006', 'UML3-VIEW-007',
			'UML3-VIEW-008', 'UML3-VIEW-009';
		#traces dependency from PresentUML3ViewsInTool to 'UML3-VIEW-001', 'UML3-VIEW-006', 'UML3-VIEW-007',
			'UML3-VIEW-010', 'UML3-VIEW-011', 'UML3-VIEW-012', 'UML3-VIEW-013', 'UML3-VIEW-014',
			UML3VerificationRequirements::'UML3-VER-006';
	}

	package Realization {
		doc
		/*
		Realization: the view definitions that realize the done and tbc VIEW requirements.

		Contents:
		- #realizes dependencies from UML3Views definitions, and from the standard view definitions that UML3
		  uses as-is, to VIEW requirements.
		*/
		#realizes dependency from UML3Views::ClassDiagram to 'UML3-VIEW-001';
		#realizes dependency from UML3Views::ComponentDiagram to 'UML3-VIEW-001';
		#realizes dependency from UML3Views::SequenceDiagram to 'UML3-VIEW-001';
		#realizes dependency from UML3Views::ClassTable to 'UML3-VIEW-001';
		#realizes dependency from UML3Views::ClassDiagram to 'UML3-VIEW-002';
		#realizes dependency from UML3Views::PackageDiagram to 'UML3-VIEW-002';
		#realizes dependency from UML3Views::ComponentDiagram to 'UML3-VIEW-003';
		#realizes dependency from UML3Views::DeploymentDiagram to 'UML3-VIEW-003';
		#realizes dependency from UML3Views::EntityRelationshipDiagram to 'UML3-VIEW-003';
		#realizes dependency from UML3Views::MessageSchemaView to 'UML3-VIEW-003';
		#realizes dependency from UML3Views::SequenceDiagram to 'UML3-VIEW-004';
		#realizes dependency from StandardViewDefinitions::ActionFlowView to 'UML3-VIEW-004';
		#realizes dependency from StandardViewDefinitions::StateTransitionView to 'UML3-VIEW-004';
		#realizes dependency from UML3Views::ClassDiagram to 'UML3-VIEW-006';
		#realizes dependency from UML3Views::EntityRelationshipDiagram to 'UML3-VIEW-006';
		#realizes dependency from UML3Views::ClassDiagram to 'UML3-VIEW-007';
		#realizes dependency from UML3Views::ComponentDiagram to 'UML3-VIEW-007';
		#realizes dependency from UML3Views::ClassTable to 'UML3-VIEW-007';
		#realizes dependency from UML3Views::ClassTable to 'UML3-VIEW-008';
		#realizes dependency from UML3Core::classType to 'UML3-VIEW-010';
	}
}
