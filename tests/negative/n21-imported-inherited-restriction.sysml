/* EXPECT: APPLICABILITY  - #raises (UML3IDL::raises) inherits annotatedElement : SysML::Dependency from
 * UML3Core::DependencyKind, which UML3IDL only imports; the inherited restriction must still apply. */
package N21ImportedInheritedRestriction {
	private import UML3IDL::*;
	#raises item def NotADependency;
}
