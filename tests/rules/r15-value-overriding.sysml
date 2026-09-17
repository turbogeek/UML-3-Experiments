/* EXPECT-RULES: R15  - redefinitions that override a bound value: a keyword rebinding the baseType of #dataType
 * (KerML validateFeatureValueOverriding; CATIA Magic E15) and an item def rebinding a bound attribute. The legal
 * forms (a keyword category, overriding a default value) are in r00-clean.sysml. */
package RulesR15 {
	private import ScalarValues::*;
	private import UML3Core::*;
	abstract attribute def Choice :> DataType;
	abstract attribute choices : Choice[0..*] nonunique :> dataTypes;
	metadata def <choice> ChoiceMetadata :> DataTypeMetadata {
		:>> baseType = choices meta SysML::Usage;
	}
	item def Settings { attribute limit : Integer = 10; }
	item def LargeSettings :> Settings { :>> limit = 20; }
}
