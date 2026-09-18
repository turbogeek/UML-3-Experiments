/* Experiment E20 probe (not a library): which names of a UML3 keyword definition can be written as a keyword?
 * A metadata definition has one short name and one declared name, and an alias adds a third spelling.
 * The run of 2026-09-17 used the names of that time, 'metadata def <classType> ClassMetadata' and an alias 'cls':
 * all three spellings loaded and implied the same specialization. After E21 the definition is
 * 'metadata def <classType> cls', so this probe now writes the declared name as '#cls' and gives the alias its own
 * name. (The keyword re-slotting rewrote this file mechanically at first, which made ByDeclaredName a second
 * short-name case; this version restores what the probe is for.)
 * Load after the UML3 libraries. Predictions and results: tests/cameo-experiments/e20-predictions.json. */
package UML3ProbeKeywordNames {
	private import UML3Core::*;

	/* the short name: the keyword itself */
	#classType item def ByShortName;

	/* the declared name of the same metadata definition, the terse id since E21 */
	#cls item def ByDeclaredName;

	/* an alias of the same metadata definition */
	alias classAlias for classType;
	#classAlias item def ByAlias;

	/* the keyword on a usage rather than a definition */
	part def Holder {
		#classType item byShortNameUsage : ByShortName;
	}
}
