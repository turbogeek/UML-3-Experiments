/* Fixture for tools/check_diagram_kinds.py: the view definitions of the probe kind, a palette without the annotation */
library package ViewsFixture {
	doc
	/*
	Fixture: view definitions whose filters the checker compares with the diagram-kind model.
	Contents:
	- ProbeDiagram: the view definition of the probe kind.
	*/
	private import UML3Core::*;
	view def ProbeDiagram {
		doc /* The view definition under test. */
		filter @classType;
	}
}
