/* Fixture for tools/check_diagram_kinds.py: one diagram kind, everything agrees */
package DiagramKindsFixtureOk {
	doc
	/*
	Fixture: a single diagram kind, used with the matching views and palettes fixtures.
	Contents:
	- probeKind: the kind under test.
	*/
	private import ScalarValues::*;
	private import UML3Core::*;
	part def DiagramKind {
		doc /* Same shape as UML3DiagramKinds::DiagramKind. */
		attribute label : String { doc /* Label. */ }
		attribute shows : KerML::Type[0..*] nonunique { doc /* Shown keywords. */ }
		attribute creates : KerML::Type[0..*] nonunique { doc /* Created keywords. */ }
		attribute views : KerML::Type[0..*] nonunique { doc /* Views of this kind. */ }
	}
	part probeKind : DiagramKind {
		doc /* The kind under test. */
		attribute :>> label = "probe diagram";
		attribute :>> shows = (classType meta KerML::Type);
		attribute :>> creates = (classType meta KerML::Type);
		attribute :>> views = (ViewsFixture::ProbeDiagram meta KerML::Type);
	}
}
