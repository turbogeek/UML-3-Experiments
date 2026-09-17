/* EXPECT-CAMEO: OK  (E15 prediction, recorded 2026-09-17 before the run: a keyword that specializes the category
 * UML3Core::DataTypeKind binds its own base without overriding a bound value, so the validation engine reports no
 * failure, and Selection gains the implied specializations ProbeChoice and UML3Core::DataType.) */
package UML3ProbeKeywordCategory {
	private import UML3Core::*;
	abstract attribute def ProbeChoice :> DataType;
	abstract attribute probeChoices : ProbeChoice[0..*] nonunique :> dataTypes;
	metadata def <probeChoice> ProbeChoiceMetadata :> DataTypeKind {
		:>> baseType = probeChoices meta SysML::Usage;
	}
	#probeChoice attribute def Selection;
	#dataType attribute def Amount;
}
