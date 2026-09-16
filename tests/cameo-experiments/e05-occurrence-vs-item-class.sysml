/* EXPECT-CAMEO: OK
 * Experiment E05: implications of basing UML Class on 'occurrence def' instead of 'item def'.
 * SysML v2 kernel: Item :> Object :> Occurrence; Performance (behaviors) :> Occurrence;
 * Object is disjoint from Performance; Occurrence is disjoint from DataValue.
 * Predictions: e05-predictions.json (committed before running). */

/* Occurrence-based Class: one keyword for structures, behaviors, plain occurrences, associations */
package UML3ExperimentOccurrenceClass {
	private import ScalarValues::*;
	private import Metaobjects::SemanticMetadata;

	abstract occurrence def OClass;
	abstract occurrence oclasses : OClass[0..*] nonunique;
	metadata def <oclass> OClassMetadata :> SemanticMetadata {
		:>> baseType = oclasses meta SysML::Usage;
	}

	#oclass item def CustomerItem { attribute name : String; }
	#oclass part def OrderServicePart;
	#oclass action def ProcessOrder { in customer : CustomerItem; }
	#oclass occurrence def Session { attribute startedAt : String; }
	#oclass connection def Knows {
		end ref a : CustomerItem;
		end ref b : CustomerItem;
	}
	#oclass item customerInstance : CustomerItem;
}

/* An occurrence-based class used where SysML requires an item (port item, flow payload) */
package UML3ExperimentOccurrenceItemTyping {
	private import UML3ExperimentOccurrenceClass::*;

	abstract occurrence def OMessage :> OClass;
	port def MessageOut {
		out item msg : OMessage[0..*];
	}
}

/* An occurrence-based class keyword on a data type (DataValue is disjoint from Occurrence) */
package UML3ExperimentOccurrenceDataType {
	private import UML3ExperimentOccurrenceClass::*;

	#oclass attribute def Money;
}

/* Contrast: the CURRENT item-based #classType on a behavior (Object is disjoint from Performance) */
package UML3ExperimentItemClassOnAction {
	private import UML3Core::*;

	#classType action def PlaceOrderBehavior;
}
