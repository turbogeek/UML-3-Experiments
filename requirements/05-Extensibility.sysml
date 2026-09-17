package UML3ExtensibilityRequirements {
	doc
	/*
	EXT: requirements on extending UML3: user-defined semantic keywords, valued metadata, applicability
	declarations, extension libraries built on UML3, checking of extended models, versioning of extensions
	and the migration of UML 2.x profiles.

	Contents:
	- Defining extensions: userSemanticKeywords, layeredExtensionLibraries, valuedMetadata,
	  applicabilityDeclarations.
	- Checking and combining extensions: rulesFollowSpecialization, modelDefinedRules, stackedKeywords.
	- Evolution and migration: versionedExtensions, profileMigration.
	- Relationships and names: relationshipKeywords, keywordNameConflicts.
	- UseCases: how extension authors, tool vendors and reviewers use the extension mechanism.
	- Realization: the library elements that realize the done and tbc requirements.
	References: docs/REQUIREMENTS-GUIDE.md; docs/DESIGN.md; UML 2.5.1 Stereotype; KerML 9.2.16; SysML 7.27.3.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;
	private import UML3Types::*;
	private import UML3Data::*;
	private import UML3Messaging::*;

	requirement <'UML3-EXT-001'> userSemanticKeywords {
		doc
		/*
		Users shall be able to define semantic keywords in the same way as the UML3 keywords: a metadata
		definition that specializes SemanticMetadata and whose base type is a library usage, typed by a base
		definition that gives the keyword its meaning or by Anything for a marker. Applying such a keyword
		shall give the annotated element the implied specialization of its base, as for a UML3 keyword.
		Verified by: E01; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "UML3 is itself defined with this mechanism, and giving users the same mechanism lets domains extend UML3 as UML stereotypes do, but with real semantics instead of labels."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-EXT-002'> layeredExtensionLibraries {
		doc
		/*
		Users shall be able to publish extension libraries whose base definitions specialize UML3 base
		definitions, without changing the UML3 libraries. Elements marked with the keywords of such a library
		shall also be instances of the UML3 concepts that the library refines, and queries on those concepts
		shall find them.
		Verified by: tools/run_tests.py suite cameo; library/UML3Data.sysml; library/UML3Messaging.sysml.
		*/
		@Rationale { text = "Domain and company libraries must build on UML3 concepts instead of copying them, so that a class, an operation or an association means the same in every extended model."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-EXT-003'> valuedMetadata {
		doc
		/*
		Users shall be able to define metadata with typed attributes, defaults and enumerated values (tagged
		values), and to apply it with values for those attributes, both alone and on elements that also carry
		semantic keywords.
		Verified by: tools/run_tests.py suite cameo; tools/run_tests.py suite idl-import; examples/03-OnlineStoreMessaging.sysml.
		*/
		@Rationale { text = "Many design decisions are values rather than kinds, such as a delivery guarantee, a referential action or a size limit, which UML profiles record as tagged values."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-EXT-004'> applicabilityDeclarations {
		doc
		/*
		A user keyword shall declare the kinds of elements it applies to, through the base type of a semantic
		keyword or the annotated element restriction of plain metadata, and UML3 tooling shall report a user
		keyword applied to an element outside that declaration.
		Verified by: tools/run_tests.py suite negative; tools/run_tests.py suite checker-calibration; E01.
		*/
		@Rationale { text = "SysML v2 tools build implied specializations for misapplied keywords without an error, so every extension, not only UML3 itself, needs a declared and checked applicability."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-EXT-005'> rulesFollowSpecialization {
		doc
		/*
		UML3 checks, views and generators that apply to a UML3 concept shall apply to every element that has the
		semantics of that concept, including an element marked with a user keyword whose base specializes the
		concept or whose metadata definition specializes the UML3 keyword.
		*/
		@Rationale { text = "An extension that escapes the design rules and views of the concept it refines defeats layering, which happens whenever a tool selects elements by keyword name instead of by semantics."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-EXT-006'> modelDefinedRules {
		doc
		/*
		Users shall be able to state the constraints of an extension, such as the constraints of a UML
		stereotype, as model elements of the extension library, and UML3 tooling shall evaluate them on the
		models that apply the extension.
		*/
		@Rationale { text = "UML profiles carry OCL constraints with their stereotypes, and rules that live only in tool code must be reimplemented by every tool and cannot be reviewed with the extension."; }
		@StatusInfo { status = StatusKind::tbd; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-EXT-007'> stackedKeywords {
		doc
		/*
		An element shall be able to carry several semantic keywords from UML3 and from extension libraries, and
		each keyword shall give the element the implied specialization of its base.
		Verified by: E02; E03; tools/run_tests.py suite rules-tests.
		*/
		@Rationale { text = "Extensions are combined on one element, such as an aggregate root that is also audited, and KerML gives every semantic metadata its effect; a tool that applies only the first keyword changes the meaning of the model."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-EXT-008'> versionedExtensions {
		doc
		/*
		An extension library shall state its version and the versions of the UML3 libraries it builds on, and
		a model shall be able to state the extension versions it uses, so that a tool can detect incompatible
		combinations.
		*/
		@Rationale { text = "Extension libraries evolve separately from UML3 and from the models that use them, and without versions a changed extension silently changes the meaning of existing models."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-EXT-009'> profileMigration {
		doc
		/*
		UML3 shall define a mapping from UML 2.x profiles to UML3 extensions that covers stereotypes and the
		metaclasses they extend, stereotype generalization, tagged values and their types, required
		stereotypes and stereotype constraints, so that profiles and the models that apply them can be migrated.
		*/
		@Rationale { text = "Organizations have invested in UML 2.x profiles such as MARTE and SoaML, and a defined mapping lets them move to UML3 without redesigning their extensions."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
	}

	requirement <'UML3-EXT-010'> relationshipKeywords {
		doc
		/*
		Users shall be able to define keywords for relationships that cannot be specialized, such as
		dependencies, as plain metadata restricted to that kind of relationship. UML3 tooling shall report such
		a keyword on any other kind of element, including a restriction inherited from a more general keyword.
		Verified by: tools/run_tests.py suite negative; tools/run_tests.py suite cameo-probes; library/UML3Core.sysml.
		*/
		@Rationale { text = "Dependencies such as uses, calls or maps-to need their kind recorded, but a dependency is a relationship rather than a type, so semantic metadata cannot give it semantics."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-EXT-011'> keywordNameConflicts {
		doc
		/*
		UML3 tooling shall report a keyword name that resolves to metadata definitions of more than one library
		where it is applied, and UML3 shall give naming guidance that lets independent extension libraries be
		combined in one model.
		*/
		@Rationale { text = "Independent extension libraries will reuse short names such as entity or service, and a tool that silently picks one gives the element a meaning its author did not intend."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	package UseCases {
		doc
		/*
		UseCases: how extension authors, tool vendors and reviewers use the UML3 extension mechanism.

		Contents:
		- PublishDomainExtension: a software architect publishes an extension library for a domain.
		- MigrateUML2Profiles: a tool vendor migrates UML 2.x profiles and the models that apply them.
		- CheckModelWithExtensions: a reviewer checks a model that combines UML3 with extension libraries.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def PublishDomainExtension {
			doc
			/*
			A software architect creates an extension library for a domain or an organization: semantic
			keywords that refine UML3 concepts, valued metadata, keywords for dependencies, applicability
			declarations and rules, and publishes it with a version.
			*/
			subject environment : UML3Environment;
			actor architect : SoftwareArchitect;
			objective {
				doc /* Teams apply the extension like UML3 itself, and extended models keep UML3 semantics, checks and views. */
			}
		}

		use case def MigrateUML2Profiles {
			doc
			/*
			A tool vendor migrates a UML 2.x profile and the models that apply it: stereotypes become semantic
			keywords or plain metadata, tagged values become metadata attributes, and stereotype constraints
			become extension rules.
			*/
			subject environment : UML3Environment;
			actor vendor : ToolVendor;
			objective {
				doc /* Profiled UML 2.x models become UML3 models with the same meaning, without redesigning the profile. */
			}
		}

		use case def CheckModelWithExtensions {
			doc
			/*
			A reviewer checks a model that combines UML3 with several extension libraries: keywords are applied
			to allowed elements, stacked keywords all take effect, keyword names do not conflict, and the rules
			of refined UML3 concepts also apply to extended elements.
			*/
			subject environment : UML3Environment;
			actor reviewer : Reviewer;
			objective {
				doc /* Misused or conflicting extensions are reported before the model is used for generation or decisions. */
			}
		}

		#traces dependency from PublishDomainExtension to 'UML3-EXT-001', 'UML3-EXT-002', 'UML3-EXT-003', 'UML3-EXT-004',
			'UML3-EXT-006', 'UML3-EXT-008', 'UML3-EXT-010';
		#traces dependency from MigrateUML2Profiles to 'UML3-EXT-001', 'UML3-EXT-003', 'UML3-EXT-004', 'UML3-EXT-006',
			'UML3-EXT-009', UML3CoreRequirements::'UML3-CORE-005';
		#traces dependency from CheckModelWithExtensions to 'UML3-EXT-004', 'UML3-EXT-005', 'UML3-EXT-006', 'UML3-EXT-007',
			'UML3-EXT-011', UML3CoreRequirements::'UML3-CORE-008';
	}

	package Realization {
		doc
		/*
		Realization: the KerML and UML3 library elements that realize the done and tbc EXT requirements.

		Contents:
		- #realizes dependencies from library elements to EXT requirements.
		*/
		#realizes dependency from Metaobjects::SemanticMetadata to 'UML3-EXT-001';
		#realizes dependency from UML3Core::ClassMetadata to 'UML3-EXT-001';
		#realizes dependency from UML3Data::EntityMetadata to 'UML3-EXT-002';
		#realizes dependency from UML3Messaging::DomainEventMetadata to 'UML3-EXT-002';
		#realizes dependency from UML3Types::Facets to 'UML3-EXT-003';
		#realizes dependency from UML3Messaging::QualityOfService to 'UML3-EXT-003';
		#realizes dependency from Metaobjects::SemanticMetadata to 'UML3-EXT-004';
		#realizes dependency from UML3Core::DependencyKind to 'UML3-EXT-004';
		#realizes dependency from Metaobjects::SemanticMetadata to 'UML3-EXT-007';
		#realizes dependency from UML3Core::DependencyKind to 'UML3-EXT-010';
		#realizes dependency from UML3Data::MapsTo to 'UML3-EXT-010';
	}
}
