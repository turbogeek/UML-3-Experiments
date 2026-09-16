/* EXPECT-CAMEO: OK
 * Experiment E01 (not adopted into the library): can a plain metadata keyword such as #primaryKey
 * become a SEMANTIC keyword, so CATIA Magic shows it as a label, while still being valid on both
 * attribute usages and ref item usages? The baseType is a reference usage typed by Base::Anything,
 * which belongs to no disjoint family (DataValue / Object / Performance).
 * Predictions: tests/cameo-experiments/e01-predictions.json (committed before running). */
package UML3ExperimentSemanticKey {
	private import ScalarValues::*;
	private import Metaobjects::SemanticMetadata;
	private import UML3Types::*;

	abstract ref keyFeatures : Base::Anything[0..*] nonunique;

	metadata def <pk> PrimaryKeyKeyword :> SemanticMetadata {
		:>> baseType = keyFeatures meta SysML::Usage;
	}

	item def Account {
		#pk attribute accountId : Uuid;
		ref #pk item owner : Account[0..1];
	}

	/* control: same shapes without the keyword */
	item def PlainAccount {
		attribute accountId : Uuid;
		ref item owner : PlainAccount[0..1];
	}
}
