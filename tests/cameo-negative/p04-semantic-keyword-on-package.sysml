/* EXPECT-CAMEO: OK  (observed 2026-09-16: builder accepts; UML3 APPLICABILITY check rejects)
 * ORIGINAL PREDICTION (refuted): error. SemanticMetadata requires its annotated element to be a Type; a package is not -> error. Confidence: medium-high. */
package UML3ProbeSemanticOnPackage {
	private import UML3Core::*;
	#classType package Domain;
}
