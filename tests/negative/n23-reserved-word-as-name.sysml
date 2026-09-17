/* EXPECT: LINT  - a reserved word cannot be a declared name: 'first' belongs to the succession syntax, so
 * 'enum first { ... }' is rejected by CATIA Magic and by the ANTLR validator (E12). */
package N23ReservedWordAsName {
	enum def Kind {
		enum first { doc /* The first kind. */ }
	}
}
