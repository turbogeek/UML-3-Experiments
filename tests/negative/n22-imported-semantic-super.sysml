/* EXPECT: APPLICABILITY  - #union is semantic through UML3Core::DataTypeKind, which UML3IDL only imports; semantic
 * metadata needs a type as its annotated element, and a package is not one (compare n15). */
package N22ImportedSemanticSuper {
	private import UML3IDL::*;
	#union package Choices;
}
