/* EXPECT-CAMEO: OK
 * Experiment E04: can @Navigable become a SEMANTIC keyword on association END features without
 * breaking connection definitions or the connection usages that bind their ends?
 * Tests body form (as used in the examples) and prefix form on an 'end item'.
 * Predictions: e04-predictions.json (committed before running). */
package UML3ExperimentNavigable {
	private import Base::Anything;
	private import Metaobjects::SemanticMetadata;
	private import UML3Core::*;

	abstract ref navigableEnds : Anything[0..*] nonunique;

	metadata def <navigable> NavigableKeyword :> SemanticMetadata {
		:>> baseType = navigableEnds meta SysML::Usage;
	}

	item def Buyer;
	item def Purchase;

	/* body form, like examples/01 */
	#association connection def BuysBody {
		end [1] ref buyer : Buyer { @NavigableKeyword; }
		end [0..*] ref purchase : Purchase;
	}

	/* prefix form on an end item usage */
	#association connection def BuysPrefix {
		end [1] #navigable item buyer : Buyer;
		end [0..*] item purchase : Purchase;
	}

	/* connection usages binding the ends */
	part def Store {
		item shopper : Buyer;
		item purchases : Purchase[0..*];
		connection viaBody : BuysBody connect shopper to purchases;
		connection viaPrefix : BuysPrefix connect shopper to purchases;
	}
}
