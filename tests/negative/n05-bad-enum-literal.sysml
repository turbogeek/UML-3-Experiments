/* EXPECT: QUALIFIED  - enum literal that does not exist, inside a value expression */
package N05 {
	private import UML3Data::*;
	#table item def T {
		#foreignKey attribute FK : ScalarValues::String {
			@ForeignKey { onDelete = ReferentialAction::deleteEverything; }
		}
	}
}
