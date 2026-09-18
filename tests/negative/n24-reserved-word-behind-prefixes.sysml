/* EXPECT: LINT  - a reserved word cannot be a declared name even when prefixes and a keyword come first:
 * 'subject' introduces the subject of a requirement or case, so 'abstract ref #templateParameter item subject' is
 * rejected by the ANTLR validator. The declared-name check used to start only at a declaration keyword that opens
 * the statement, so the E22 pattern probe's role 'subject' passed it. */
package N24ReservedWordBehindPrefixes {
	private import UML3Core::*;
	#interfaceType item def Subject;
	abstract #template part def ObserverRoles {
		abstract ref #templateParameter item subject : Subject[1];
	}
}
