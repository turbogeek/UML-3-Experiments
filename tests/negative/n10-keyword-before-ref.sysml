/* EXPECT: LINT  - keyword before ref (Cameo: no viable alternative at input #foreignKeyref) */
package N10 {
	private import UML3Data::*;
	item def A;
	item def B {
		#foreignKey ref item a : A[1];
	}
}
