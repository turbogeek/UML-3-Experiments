/* Checker regression: a reserved word written as a quoted name is a legal name. The IDL importer escapes IDL names
 * that are SysML keywords this way ('struct', 'state'). The widened reserved-word rule of E22 first reported
 * these, because the tokenizer drops the quotes; quoted tokens are now never read as keywords. Must pass clean. */
package QuotedReservedNames {
	private import ScalarValues::*;

	attribute def 'struct' {
		attribute 'state' : String;
		attribute 'part' : Integer;
		attribute 'ref' : Boolean;
	}

	enum def 'enum' {
		enum 'first';
		enum second;
	}

	abstract part def Roles {
		abstract ref item 'subject' : 'struct'[1];
	}
}
