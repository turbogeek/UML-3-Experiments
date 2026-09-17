/* EXPECT: LINT - direction after abstract, in a declaration that follows a comment about (a comment ends without a semicolon) */
package N20PrefixOrderAfterComment {
	private import ScalarValues::*;
	action def Op {
		comment Why about Op /* explains Op */
		abstract out item result : Real;
	}
}
