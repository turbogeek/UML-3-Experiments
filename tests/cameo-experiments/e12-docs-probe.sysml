package UML3E12DocsProbe {
	doc
	/*
	E12 probe: how CATIA Magic stores and relates UML3 documentation.
	Contents:
	- A, B: documented part definitions; Kind: an enumeration with documented literals (initial, later).
	- Design: a named comment about A and B; StarDoc: a part def whose doc keeps star decoration.
	- statusCheck: a requirement using ModelingMetadata status done.
	*/
	private import ModelingMetadata::*;

	part def A { doc /* Documentation of A. */ }
	part def B { doc /* Documentation of B. */ }

	comment Design about A, B
		/*
		How A and B work together.
		*/

	part def StarDoc {
		doc
		/*
		 * First line with star decoration.
		 * Second line.
		 */
	}

	enum def Kind {
		doc /* Kinds. */
		enum initial { doc /* The first kind; not named 'first', which is a reserved word (E12). */ }
		enum later { doc /* The second kind. */ }
	}

	requirement <'E12-REQ-1'> statusCheck {
		doc /* The probe shall resolve StatusKind::done. */
		@StatusInfo { status = StatusKind::done; }
		@Rationale { text = "Checks that done is accepted as a literal name."; }
	}
}
