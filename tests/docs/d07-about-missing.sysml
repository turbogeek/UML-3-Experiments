package DocsAboutMissing {
	doc
	/*
	A comment about an element that does not exist.
	Contents:
	- A: a part definition, with a nested attribute x.
	*/
	part def A {
		doc /* A. */
		attribute x : ScalarValues::Real { doc /* x. */ }
	}

	comment Resolves about A, A::x
		/*
		Both names exist, so this comment is fine.
		*/

	comment Broken about A, A::y
		/*
		A::y does not exist.
		*/
}
