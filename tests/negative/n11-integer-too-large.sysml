/* EXPECT: LINT  - integer literal beyond 32-bit int (Cameo: Integer number too large) */
package N11 {
	private import UML3Types::*;
	attribute def Big :> UInt32 {
		@Facets { maxInclusive = 4294967295; }
	}
}
