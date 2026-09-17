/* EXPECT-RULES: none  - regression: @Metadata inside a view filter expression is a test, not an applied keyword */
package RulesR13 {
	private import StandardViewDefinitions::*;
	private import UML3Data::*;
	private import UML3Messaging::*;
	view def TablesOnly :> GeneralView {
		filter @table or @entity or @topic or @domainEvent;
	}
}
