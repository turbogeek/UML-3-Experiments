package FixtureExternalRequirements {
	doc
	/*
	FixtureExternalRequirements: a small external requirement set for the tools/check_refinements.py fixtures.

	Contents:
	- firstNeed, secondNeed: mandatory requirements.
	- optionalNeed: an optional requirement.
	- openQuestion: a concern with a nested follow-up question.
	*/
	private import UML3Requirements::*;

	requirement <'EXT-1'> firstNeed {
		doc /* The product shall model classes. */
		@Priority { level = PriorityKind::mandatory; }
	}

	requirement <'EXT-2'> secondNeed {
		doc /* The product shall have a grammar of its own. */
		@Priority { level = PriorityKind::mandatory; }
	}

	requirement <'EXT-3'> optionalNeed {
		doc /* The product may move models between its implementations. */
		@Priority { level = PriorityKind::optional; }
	}

	concern <'EXT-4'> openQuestion {
		doc /* Are the native behaviors enough? */
		concern <'EXT-4.1'> followUp {
			doc /* If not, what should be added? */
		}
	}
}
