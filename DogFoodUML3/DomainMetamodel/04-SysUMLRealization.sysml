package DMMSysUMLRealization {
	doc
	/*
	DMMSysUMLRealization: which element of SysUML, of the SysML v2 libraries or of the reflective metamodel realizes
	each concept of the domain metamodel. It is the SysUML half of the alignment that UML3-IMPL-003 requires; the
	UML3 half follows when UML3 exists (UML3-IMPL-002), and the two halves are what the round trip transforms
	between (UML3-IMPL-005).

	A concept whose name is also a SysUML library name is qualified on both sides, because a package that imported
	both would hide the two names against each other (KerML 7.2.5).

	Contents:
	- Foundation: identity, namespaces, packages and relationships, realized by the reflective metamodel.
	- Structure: the classifiers, features and relationships of a class model, realized by UML3Core keywords and by
	  SysML v2 constructs.
	- Surface: keyword forms and diagram kinds, realized by semantic metadata and by UML3DiagramKinds, and the
	  presentation concepts that SysUML does not realize.
	References: KerML 7.2.5; SysML 7.27; requirements/22-Implementations.sysml.
	*/
	private import UML3Core::*;

	comment RealizesTheRequirement about DMMFoundation, DMMStructure, DMMSurface
		/*
		The metamodel is what UML3-IMPL-012 asks for, so the three layers realize that requirement. The dependency
		goes from here to the requirement, not the other way round: the model of this effort refers to the
		requirements, and the requirements do not refer to it.
		*/
	#realizes dependency from DMMFoundation, DMMStructure, DMMSurface, DMMSysUMLRealization
		to UML3ImplementationRequirements::'UML3-IMPL-012';

	package Foundation {
		doc
		/*
		Foundation: the concepts every element has are realized by the reflective KerML metamodel that SysML v2
		publishes, not by SysUML, because SysML v2 already provides them.

		Contents:
		- #realizes dependencies from the metamodel elements to the DMMFoundation concepts.
		*/
		#realizes dependency from SysML::Element to DMMFoundation::ModelElement;
		#realizes dependency from SysML::VisibilityKind to DMMFoundation::VisibilityKind;
		#realizes dependency from SysML::Namespace to DMMFoundation::Namespace;
		#realizes dependency from SysML::Package to DMMFoundation::Package;
		#realizes dependency from SysML::Relationship to DMMFoundation::Relationship;
		comment DirectedRelationships about DMMFoundation::DirectedRelationship
			/*
			KerML has one Relationship metaclass with source and target features, so the same element realizes both
			the relationship concept and the directed one.
			*/
		#realizes dependency from SysML::Relationship to DMMFoundation::DirectedRelationship;
	}

	package Structure {
		doc
		/*
		Structure: the class model concepts are realized by the UML3Core definitions and their keywords, and by the
		SysML v2 constructs that SysUML uses as they are.

		Contents:
		- #realizes dependencies from the SysUML and SysML v2 elements to the DMMStructure concepts.
		- AssociationClasses, Parameters: notes on the two realizations that are not one element each.
		*/
		#realizes dependency from SysML::Definition to DMMStructure::Classifier;
		#realizes dependency from UML3Core::Class, UML3Core::classType to DMMStructure::Class;
		#realizes dependency from UML3Core::ActiveClass, UML3Core::activeClass to DMMStructure::ActiveClass;
		#realizes dependency from UML3Core::DataType, UML3Core::dataType to DMMStructure::DataType;
		#realizes dependency from SysML::AttributeDefinition, UML3Types::Facets to DMMStructure::ScalarType;
		#realizes dependency from UML3Types::Facets to DMMStructure::FacetValue, DMMStructure::FacetKind;
		#realizes dependency from SysML::EnumerationDefinition to DMMStructure::Enumeration;
		#realizes dependency from SysML::EnumerationUsage to DMMStructure::EnumerationLiteral;
		#realizes dependency from UML3Core::InterfaceType, UML3Core::interfaceType to DMMStructure::InterfaceType;
		#realizes dependency from UML3Core::Signal, UML3Core::signal to DMMStructure::Signal;
		#realizes dependency from UML3Core::ExceptionType, UML3Core::exceptionType to DMMStructure::ExceptionType;
		#realizes dependency from SysML::Usage to DMMStructure::TypedElement, DMMStructure::Feature,
			DMMStructure::StructuralFeature;
		#realizes dependency from SysML::AttributeUsage, UML3Core::static, UML3Core::id to DMMStructure::Attribute;
		#realizes dependency from UML3Core::operation, UML3Core::query, UML3Core::constructor to DMMStructure::Operation;
		#realizes dependency from SysML::FeatureDirectionKind to DMMStructure::ParameterDirectionKind;
		#realizes dependency from SysML::Subclassification to DMMStructure::Generalization;
		#realizes dependency from UML3Core::GeneralizationSet, UML3Core::InGeneralizationSet
			to DMMStructure::GeneralizationSet;
		#realizes dependency from UML3Core::realizes to DMMStructure::InterfaceRealization;
		#realizes dependency from UML3Core::Association, UML3Core::association to DMMStructure::Association;
		#realizes dependency from UML3Core::navigable to DMMStructure::AssociationEnd;
		#realizes dependency from UML3Core::AggregationKind, UML3Core::Aggregation, UML3Core::Composition
			to DMMStructure::AggregationKind;
		#realizes dependency from SysML::Dependency to DMMStructure::Dependency;
		#realizes dependency from UML3Core::DependencyKind, UML3Core::uses, UML3Core::creates, UML3Core::calls,
			UML3Core::traces to DMMStructure::DependencyKind;
		#realizes dependency from SysML::AssertConstraintUsage to DMMStructure::Constraint;

		comment AssociationClasses about DMMStructure::AssociationClass
			/*
			SysUML has no separate element for an association that is also a class: a #association connection
			definition that owns attributes is one (UML3-STR-008, still open), so UML3Core::Association realizes both
			concepts.
			*/
		#realizes dependency from UML3Core::Association to DMMStructure::AssociationClass;

		comment Parameters about DMMStructure::Parameter
			/*
			A parameter is a directed usage in SysML v2, so the same construct realizes the parameter concept and
			the typed element it specializes; its direction is the SysML v2 feature direction.
			*/
		#realizes dependency from SysML::Usage to DMMStructure::Parameter;
	}

	package Surface {
		doc
		/*
		Surface: the vocabulary of SysUML is realized by semantic metadata (every keyword is a metadata definition
		whose base type gives the concept) and by the diagram kinds modeled in UML3DiagramKinds.

		Contents:
		- #realizes dependencies from the metadata mechanism and the diagram kind model to the DMMSurface concepts.
		- Presentations: why the presentation concepts have no realization yet.
		*/
		#realizes dependency from Metaobjects::SemanticMetadata to DMMSurface::KeywordForm;
		#realizes dependency from UML3DiagramKinds::DiagramKind to DMMSurface::DiagramKind;
		#realizes dependency from UML3DiagramKinds::CreationForm to DMMSurface::CreationForm;
		#realizes dependency from UML3Core, UML3DiagramKinds to DMMSurface::Vocabulary;

		comment Presentations about DMMSurface::Presentation, DMMSurface::TextualPresentation,
			DMMSurface::DiagramShape, DMMSurface::Label, DMMSurface::Compartment, DMMSurface::PaletteEntry
			/*
			SysML v2 has no standard interchange for presentations: the text of a model is its source file, and the
			shapes, labels and compartments of a diagram are data of the modeling tool, as are the palette entries,
			which CATIA Magic builds from customization/catia-magic. So the presentation concepts have no element
			that realizes them, which is what makes a diagram the part of a model that the round trip cannot carry
			(UML3-IMPL-005, UML3-IMPL-010).
			*/
	}
}
