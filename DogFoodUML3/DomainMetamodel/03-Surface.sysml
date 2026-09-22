package DMMSurface {
	doc
	/*
	DMMSurface: the surface data of a model, how its underlying elements are written, labeled and drawn, without
	fixing the textual or graphical notation of either implementation.

	Two things are kept apart, as the OMG keeps a model apart from its diagram interchange. The vocabulary says what
	an implementation offers: the keyword forms that mark an element as a concept, the diagram kinds that show
	concepts and the palette entries that create them. A presentation says how one particular element appears: the
	keyword forms it was written with, and the shape, label and compartments that show it on a diagram. A
	presentation refers to the element it shows and adds no meaning to it, so dropping every presentation leaves the
	model complete.

	Contents:
	- ConceptKind: the concepts of the underlying data that a surface form can stand for.
	- NotationKind, CreationForm: the notations, and the definition-or-usage choice of a palette.
	- Vocabulary, KeywordForm, DiagramKind, PaletteEntry: what an implementation offers.
	- Presentation, TextualPresentation, DiagramShape, Label, Compartment: how an element appears.
	References: UML3DiagramKinds; SysML 7.26; UML 2.5.1 Package.
	*/
	private import ScalarValues::*;
	private import UML3Core::*;
	private import DMMFoundation::*;
	private import DMMStructure::Feature;

	enum def ConceptKind {
		doc
		/*
		The concepts that a keyword form, a diagram kind or a palette entry can stand for: one literal per concept
		of DMMStructure and DMMFoundation that a modeler creates. Reserved words are written in quotes.
		*/
		enum 'package' {
			doc /* DMMFoundation::Package. */
		}
		enum 'class' {
			doc /* DMMStructure::Class. */
		}
		enum activeClass {
			doc /* DMMStructure::ActiveClass. */
		}
		enum dataType {
			doc /* DMMStructure::DataType. */
		}
		enum scalarType {
			doc /* DMMStructure::ScalarType. */
		}
		enum enumeration {
			doc /* DMMStructure::Enumeration. */
		}
		enum enumerationLiteral {
			doc /* DMMStructure::EnumerationLiteral. */
		}
		enum interfaceType {
			doc /* DMMStructure::InterfaceType. */
		}
		enum signal {
			doc /* DMMStructure::Signal. */
		}
		enum exceptionType {
			doc /* DMMStructure::ExceptionType. */
		}
		enum 'attribute' {
			doc /* DMMStructure::Attribute. */
		}
		enum operation {
			doc /* DMMStructure::Operation. */
		}
		enum parameter {
			doc /* DMMStructure::Parameter. */
		}
		enum 'association' {
			doc /* DMMStructure::Association. */
		}
		enum associationEnd {
			doc /* DMMStructure::AssociationEnd. */
		}
		enum associationClass {
			doc /* DMMStructure::AssociationClass. */
		}
		enum generalization {
			doc /* DMMStructure::Generalization. */
		}
		enum generalizationSet {
			doc /* DMMStructure::GeneralizationSet. */
		}
		enum interfaceRealization {
			doc /* DMMStructure::InterfaceRealization. */
		}
		enum 'dependency' {
			doc /* DMMStructure::Dependency. */
		}
		enum 'constraint' {
			doc /* DMMStructure::Constraint. */
		}
	}

	enum def NotationKind {
		doc /* The notations in which the underlying data surfaces. */
		enum textual {
			doc /* Text that a modeler writes and a grammar parses. */
		}
		enum graphical {
			doc /* Shapes, lines and labels on a diagram. */
		}
		enum tabular {
			doc /* Rows and columns of a table or a matrix. */
		}
	}

	enum def CreationForm {
		doc /* Whether a palette entry creates the definition of a concept or a usage of one. */
		enum definition {
			doc /* The definition: the diagram is a model of types. */
		}
		enum usage {
			doc /* A usage: the diagram is a configuration of parts. */
		}
	}

	#classType item def Vocabulary :> Namespace {
		doc /* What one implementation offers on the surface: its keyword forms, diagram kinds and palette entries. */
		attribute notation : NotationKind[1..*] {
			doc /* The notations this vocabulary covers. */
		}
		item keywordForms : KeywordForm[0..*] :> ownedElements {
			doc /* The spellings that mark an element as a concept. */
		}
		item diagramKinds : DiagramKind[0..*] :> ownedElements {
			doc /* The kinds of diagram the implementation offers. */
		}
	}

	#classType item def KeywordForm :> ModelElement {
		doc
		/*
		A spelling that marks an element as a concept of the underlying data, such as a keyword of a textual
		notation. Several forms may stand for the same concept, as a terse spelling does for the full one, and each
		form stands for exactly one concept, so a model written with either form has one meaning.
		*/
		attribute spelling : String {
			doc /* The spelling as it is written, without the marker character of the notation. */
		}
		attribute terseSpelling : String[0..1] {
			doc /* A shorter spelling with the same meaning, where the implementation offers one. */
		}
		attribute notation : NotationKind {
			doc /* The notation the spelling belongs to. */
		}
		attribute represents : ConceptKind {
			doc /* The concept that an element marked with this form is an instance of. */
		}
	}

	#classType item def DiagramKind :> ModelElement {
		doc /* A kind of diagram: which concepts it shows, which it creates, and in which form it creates them. */
		attribute label : String {
			doc /* The name a tool shows for the kind, such as "class diagram". */
		}
		attribute shows : ConceptKind[0..*] {
			doc /* The concepts whose elements appear on a diagram of this kind. */
		}
		item paletteEntries : PaletteEntry[0..*] {
			doc /* What the palette of this kind offers. */
		}
		attribute defaultForm : CreationForm[0..1] {
			doc /* The form a palette offers first, where a concept has both a definition and a usage. */
		}
	}

	#classType item def PaletteEntry :> ModelElement {
		doc /* One entry of a palette: the concept it creates and the forms it offers. */
		attribute label : String {
			doc /* The name the palette shows. */
		}
		attribute creates : ConceptKind {
			doc /* The concept an element created with this entry is an instance of. */
		}
		attribute forms : CreationForm[1..2] {
			doc /* The forms the entry can create. */
		}
		attribute focusedForm : CreationForm {
			doc /* The form the entry creates when it is used without choosing. */
		}
	}

	abstract #classType item def Presentation :> ModelElement {
		doc /* How one element of the underlying data appears in one notation. It adds no meaning to the element. */
		ref item presents : ModelElement {
			doc /* The element that this presentation shows. */
		}
		attribute notation : NotationKind {
			doc /* The notation of this presentation. */
		}
	}

	#classType item def TextualPresentation :> Presentation {
		doc /* How an element is written in a textual notation. */
		ref item keywordForms : KeywordForm[0..*] ordered {
			doc /* The keyword forms the element was written with, in the order they were written. */
		}
		attribute location : String[0..1] {
			doc /* Where the text is, such as a file and a line. */
		}
	}

	#classType item def DiagramShape :> Presentation {
		doc /* How an element appears on a diagram: its shape with its label and compartments. */
		ref item diagramKind : DiagramKind {
			doc /* The kind of diagram the shape is on. */
		}
		item label : Label[0..1] {
			doc /* The label of the shape, where it has one. */
		}
		item compartments : Compartment[0..*] ordered {
			doc /* The compartments of the shape, in the order they are drawn. */
		}
	}

	#classType item def Label :> ModelElement {
		doc /* Text drawn on a shape or a line, such as the keyword of the element it shows. */
		attribute text : String {
			doc /* The text as drawn. */
		}
	}

	#classType item def Compartment :> ModelElement {
		doc
		/*
		One compartment of a shape, such as the attributes or the operations of a class. A compartment may be
		suppressed, which hides it without changing the element it belongs to.
		*/
		attribute label : String[0..1] {
			doc /* The name of the compartment, where it is drawn. */
		}
		ref item shownFeatures : Feature[0..*] ordered {
			doc /* The features the compartment lists, in the order they are drawn. */
		}
		attribute isSuppressed : Boolean {
			doc /* True when the compartment is hidden on this shape. */
		}
	}
}
