/* EXPECT-RULES: R12 */
package RulesR12 {
	private import UML3Types::*;
	private import UML3Data::*;
	#table item def T { #column #unique #primaryKey attribute ID : Uuid; }
}
