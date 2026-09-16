/* EXPECT-CAMEO: ERROR
 * PREDICTION: SemanticMetadata requires its annotated element to be a Type; a package is not -> error. Confidence: medium-high. */
package UML3ProbeSemanticOnPackage {
	private import UML3Core::*;
	#classType package Domain;
}
