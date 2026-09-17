/* EXPECT-CAMEO: OK  (E15 prediction, recorded 2026-09-17 before the run: the builder accepts the file; only the
 * validation engine rejects it, with validateFeatureValueOverriding, because ProbeUnionMetadata redefines the baseType
 * that UML3Core::DataTypeMetadata already binds. Same shape as UML3IDL::UnionMetadata in commit 761c135.) */
package UML3ProbeKeywordOverridesBase {
	private import UML3Core::*;
	abstract attribute def ProbeUnion :> DataType;
	abstract attribute probeUnions : ProbeUnion[0..*] nonunique :> dataTypes;
	metadata def <probeUnion> ProbeUnionMetadata :> DataTypeMetadata {
		:>> baseType = probeUnions meta SysML::Usage;
	}
	#probeUnion attribute def Choice;
}
