package UML3ReportRequirements {
	doc
	/*
	RPT: requirements on documents and reports generated from SysUML models: reference documents, documents
	composed of views, publication formats, requirement and traceability reports and their consistency with
	their sources, metrics, and verification, review and change reports.
	Diagrams and tables as views are in UML3ViewRequirements (VIEW).

	Contents:
	- Documents: modelReferenceDocument, viewBasedDocuments, publicationFormats.
	- Requirements and traceability: requirementsReport, traceabilityReport, reportConsistency.
	- Assessment: modelMetrics, verificationReport, reviewReport, changeReport.
	- UseCases: how technical writers, language maintainers and reviewers use generated reports.
	- Realization: the model elements that realize the done requirements.
	References: docs/UML3-Requirements.md; docs/UML2-to-UML3-Traceability.md; SysML 7.26.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;

	requirement <'UML3-RPT-001'> modelReferenceDocument {
		doc
		/*
		SysUML shall generate a reference document from any SysUML model, including the SysUML libraries: each package
		with its summary of contents, and each definition with its documentation, keywords, features,
		specializations and relationships, and the requirements and use cases of the model.
		*/
		@Rationale { text = "A standard defined as model libraries needs its reference text to come from those libraries; a separately written specification drifts away from them."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-RPT-002'> viewBasedDocuments {
		doc
		/*
		A document shall be definable in a SysUML model as a view whose ordered subviews are its sections, with their
		diagrams, tables and text, and shall be rendered from that view, so that the structure of a document is
		model content.
		*/
		@Rationale { text = "SysML v2 views can contain views and have renderings; documents defined this way are produced alike by every conforming tool from the same model."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-RPT-003'> publicationFormats {
		doc
		/*
		Generated reports shall be publishable as HTML and PDF as well as Markdown from the same generated content,
		with a stable anchor for each reported element so that other documents can link to it.
		*/
		@Rationale { text = "Markdown suits version control and review, while readers of a standard and auditors expect HTML and PDF; one content source keeps the formats consistent."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-RPT-004'> requirementsReport {
		doc
		/*
		SysUML shall publish its own requirements as a report generated from its requirement model that lists each
		requirement with its statement, rationale, priority, status, verification method and evidence, the
		elements that realize it and the use cases that trace it, and that summarizes each area by status and
		priority.
		Verified by: tools/run_tests.py suite requirements; docs/UML3-Requirements.md.
		*/
		@Rationale { text = "Reviewers and implementers read requirements as a document, and a generated document shows the current state of the model rather than an edited copy of it."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-RPT-005'> traceabilityReport {
		doc
		/*
		SysUML shall publish its traceability as reports generated from the trace sources: the traceability from
		UML 2.x concepts to SysUML with a summary by status, and the traces from requirements to the elements that
		realize them and the use cases that need them. Each report shall present every trace of its source.
		Verified by: tools/run_tests.py suite traceability; tools/run_tests.py suite requirements; docs/UML2-to-UML3-Traceability.md.
		*/
		@Rationale { text = "Practitioners and tool vendors look up how a UML concept or a requirement is realized, which needs a readable form of the trace data that stays complete."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-RPT-006'> reportConsistency {
		doc
		/*
		Each generated report shall state that it is generated, from which source and by which tool, and
		verification shall fail when a published report differs from a fresh generation from its source.
		Verified by: tools/run_tests.py suite traceability; tools/run_tests.py suite requirements.
		*/
		@Rationale { text = "A report edited by hand or generated from an older model misleads its readers while looking authoritative; a regeneration check makes a stale report fail verification."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-RPT-007'> modelMetrics {
		doc
		/*
		SysUML shall report metrics of a model: the number of elements per SysUML keyword and per package, the share
		of elements that have documentation, the design rule findings per rule, and the change of each metric
		between two versions of the model.
		*/
		@Rationale { text = "Metrics show the size, documentation and design quality of a model and how they develop, which reviews of single elements cannot show."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
	}

	requirement <'UML3-RPT-008'> reviewReport {
		doc
		/*
		SysUML shall generate a review report for a version of a model with its review findings and their status,
		its verification errors and warnings, and its requirements that are not done.
		*/
		@Rationale { text = "A review ends with a decision on one version; collecting the findings, check results and open requirements in one report gives the reviewer what the decision needs."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-RPT-009'> changeReport {
		doc
		/*
		SysUML shall generate a change report between two versions of a model that lists the added, removed and
		changed elements by package and keyword, including changes of applied keywords, metadata values and
		documentation.
		*/
		@Rationale { text = "Reviewers of a change need to see what changed in the model and not only in the text, because one textual edit can change the meaning of many elements."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
	}

	requirement <'UML3-RPT-010'> verificationReport {
		doc
		/*
		SysUML shall generate a readable verification report from the machine-readable results of a verification
		run, with the result of each suite and check, the numbers of cases and findings, the failures, and the
		time of the run.
		*/
		@Rationale { text = "Verification results copied into documentation by hand go stale; a report generated from the recorded results shows the current state and when it was produced."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	package UseCases {
		doc
		/*
		UseCases: how technical writers, language maintainers and reviewers use generated reports.

		Contents:
		- PublishModelDocumentation: a technical writer publishes reference documents generated from a model.
		- ReportRequirementsAndTraceability: a language maintainer regenerates the requirement and traceability
		  reports that a reviewer reads.
		- PrepareModelReviewPackage: a reviewer prepares the review of a model version from generated reports.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def PublishModelDocumentation {
			doc
			/*
			A technical writer generates the reference documentation of a SysUML model or library, composes
			documents from views and publishes them in the formats that their readers need.
			*/
			subject environment : UML3Environment;
			actor writer : TechnicalWriter;
			objective {
				doc /* The published documentation matches the model it was generated from and needs no editing by hand. */
			}
		}

		use case def ReportRequirementsAndTraceability {
			doc
			/*
			A language maintainer regenerates the requirement and traceability reports after a change, and a
			reviewer reads them to see what is required, what is done, and how each UML concept and requirement is
			realized.
			*/
			subject environment : UML3Environment;
			actor maintainer : LanguageMaintainer;
			actor reviewer : Reviewer;
			objective {
				doc /* The reports show the current requirements and traces, and a stale report fails verification. */
			}
		}

		use case def PrepareModelReviewPackage {
			doc
			/*
			A reviewer prepares the review of a model version with generated reports: the changes since the
			previous version, the metrics, the verification results and the open review findings.
			*/
			subject environment : UML3Environment;
			actor reviewer : Reviewer;
			objective {
				doc /* The reviewer can decide on the version from generated reports, without collecting information by hand. */
			}
		}

		#traces dependency from PublishModelDocumentation to 'UML3-RPT-001', 'UML3-RPT-002', 'UML3-RPT-003', 'UML3-RPT-006',
			UML3CoreRequirements::'UML3-CORE-006';
		#traces dependency from ReportRequirementsAndTraceability to 'UML3-RPT-004', 'UML3-RPT-005', 'UML3-RPT-006',
			UML3CoreRequirements::'UML3-CORE-005';
		#traces dependency from PrepareModelReviewPackage to 'UML3-RPT-007', 'UML3-RPT-008', 'UML3-RPT-009', 'UML3-RPT-010',
			UML3ValidationRequirements::'UML3-VAL-010';
	}

	package Realization {
		doc
		/*
		Realization: the model elements that realize the done RPT requirements.

		Contents:
		- #realizes dependencies to RPT requirements from the requirement metadata and the trace keywords that the
		  generated reports read.
		*/
		#realizes dependency from UML3Requirements to 'UML3-RPT-004';
		#realizes dependency from UML3Requirements::Priority to 'UML3-RPT-004';
		#realizes dependency from UML3Core::traces to 'UML3-RPT-005';
		#realizes dependency from UML3Core::realizes to 'UML3-RPT-005';
	}
}
