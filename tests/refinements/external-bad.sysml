package FixtureExternalRequirementsBad {
	doc
	/*
	FixtureExternalRequirementsBad: the fixture external set with form defects: secondNeed has no priority,
	EXT-3 is declared twice and openQuestion has no doc. Expected: FORM.
	*/
	private import UML3Requirements::*;

	requirement <'EXT-1'> firstNeed {
		doc /* The product shall model classes. */
		@Priority { level = PriorityKind::mandatory; }
	}

	requirement <'EXT-2'> secondNeed {
		doc /* The product shall have a grammar of its own. */
	}

	requirement <'EXT-3'> optionalNeed {
		doc /* The product may move models between its implementations. */
		@Priority { level = PriorityKind::optional; }
	}

	requirement <'EXT-3'> optionalNeedAgain {
		doc /* The same id again. */
		@Priority { level = PriorityKind::optional; }
	}

	concern <'EXT-4'> openQuestion {
		concern <'EXT-4.1'> followUp {
			doc /* If not, what should be added? */
		}
	}
}
