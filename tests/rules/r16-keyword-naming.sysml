/* EXPECT-RULES: R16  - keyword metadata defs whose two names are in the wrong slots: the keyword written as the
 * declared name with a terse short name (CATIA Magic would then label shapes «#pcls», E21), a keyword def with no
 * short name at all, a terse id that saves almost nothing, and a terse id that another library keyword already
 * uses. The correct form, 'metadata def <keyword> terseId', is in r00-clean.sysml. */
package RulesR16 {
	private import UML3Core::*;

	abstract item def ProbeThing :> Class;
	abstract item probeThings : ProbeThing[0..*] nonunique :> classes;

	/* wrong slots: the keyword belongs in the short name, because that is what a shape shows */
	metadata def <pcls> probeClassType :> SemanticMetadata {
		:>> baseType = probeThings meta SysML::Usage;
	}

	/* no short name: nothing tells a reader or a tool which word is the keyword */
	metadata def ProbeMarkerKeyword :> SemanticMetadata {
		:>> baseType = probeThings meta SysML::Usage;
	}

	/* a terse id that saves one character is not worth learning */
	metadata def <probeThing> probeThin :> SemanticMetadata {
		:>> baseType = probeThings meta SysML::Usage;
	}

	/* a terse id that UML3Core::classType already uses */
	metadata def <probeOtherThing> cls :> SemanticMetadata {
		:>> baseType = probeThings meta SysML::Usage;
	}
}
