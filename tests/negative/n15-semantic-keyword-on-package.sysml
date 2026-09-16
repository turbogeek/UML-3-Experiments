/* EXPECT: APPLICABILITY  (CATIA Magic builder accepts this silently - see tests/cameo-negative)
 * PREDICTION: SemanticMetadata requires its annotated element to be a Type; a package is not -> error. Confidence: medium-high. */
package N15ProbeSemanticOnPackage {
	private import UML3Core::*;
	#classType package Domain;
}
