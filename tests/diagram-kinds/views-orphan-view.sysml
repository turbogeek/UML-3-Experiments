/* Fixture for tools/check_diagram_kinds.py: the view definitions of the probe kind, a view definition no kind lists */
library package ViewsFixture {
	doc
	/*
	Fixture: view definitions whose filters the checker compares with the diagram-kind model.
	Contents:
	- ProbeDiagram: the view definition of the probe kind.
	- UnlistedDiagram: a view definition that no kind lists.
	*/
	private import UML3Core::*;
	view def ProbeDiagram {
		doc /* The view definition under test. */
		filter @classType;
	}
	view def UnlistedDiagram {
		doc /* A view definition that no diagram kind lists. */
		filter @classType;
	}
}
