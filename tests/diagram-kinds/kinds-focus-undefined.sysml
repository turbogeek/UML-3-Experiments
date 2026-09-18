/* Fixture for tools/check_diagram_kinds.py: a palette with a definition-and-usage menu, the kind has no defaultForm */
package DiagramKindsFixtureFocusUndefined {
	doc
	/*
	Fixture: a single diagram kind with a default creation form, used with the matching views and palettes fixtures.
	Contents:
	- CreationForm, DiagramKind: the same shape as in UML3DiagramKinds.
	- probeKind: the kind under test; it binds no defaultForm, although its palette has a menu with both forms.
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
	}
}
