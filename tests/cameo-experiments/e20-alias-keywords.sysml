/* Experiment E20 probe (not a library): which names of a UML3 keyword definition can be written as a keyword?
 * A metadata definition has one short name and one declared name ('metadata def <classType> classType'), and an
 * alias adds a third spelling. Load after the UML3 libraries.
 * Predictions: tests/cameo-experiments/e20-predictions.json, recorded before the run. */
package UML3ProbeKeywordNames {
	private import UML3Core::*;

	/* the short name, which is what UML3 models write today */
	#classType item def ByShortName;

	/* the declared name of the same metadata definition */
	#classType item def ByDeclaredName;

	/* an alias of the same metadata definition */
	alias cls for classType;
	#cls item def ByAlias;

	/* the keyword on a usage rather than a definition */
	part def Holder {
		#classType item byShortNameUsage : ByShortName;
	}
}
