/* Fixture for tools/check_diagram_kinds.py: the kind offers the definition first, the palette focuses the usage */
package DiagramKindsFixtureFocusWrong {
	doc
	/*
	Fixture: a single diagram kind with a default creation form, used with the matching views and palettes fixtures.
	Contents:
	- CreationForm, DiagramKind: the same shape as in UML3DiagramKinds.
	- probeKind: the kind under test; it is a model of types, so it offers the definition first.
	*/
	private import ScalarValues::*;
	private import UML3Core::*;
	enum def CreationForm {
		doc /* Definition or usage. */
		enum definition { doc /* The definition first. */ }
		enum usage { doc /* The usage first. */ }
	}
	part def DiagramKind {
		doc /* Same shape as UML3DiagramKinds::DiagramKind. */
		attribute label : String { doc /* Label. */ }
		attribute shows : KerML::Type[0..*] nonunique { doc /* Shown keywords. */ }
		attribute creates : KerML::Type[0..*] nonunique { doc /* Created keywords. */ }
		attribute views : KerML::Type[0..*] nonunique { doc /* Views of this kind. */ }
		attribute defaultForm : CreationForm[0..1] { doc /* The form a palette offers first. */ }
	}
	part probeKind : DiagramKind {
		doc /* The kind under test. */
		attribute :>> label = "probe diagram";
		attribute :>> shows = (classType meta KerML::Type);
		attribute :>> creates = (classType meta KerML::Type);
		attribute :>> views = (ViewsFixture::ProbeDiagram meta KerML::Type);
		attribute :>> defaultForm = CreationForm::definition;
	}
}
