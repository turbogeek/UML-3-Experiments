/* EXPECT-CAMEO: OK
 * Experiment E06: 'expose P::*' also exposes what P imports (Expose isImportAll), so library
 * elements leak into views (observed: AggregationKind in the class diagram, library ports and
 * connection bases in the component diagram). Can a filter on the reflective metaclass
 * attribute KerML::Element::isLibraryElement remove them?
 * Predictions: e06-predictions.json (committed before running). */
package UML3ExperimentViewFilters {
	private import UML3Views::*;

	view def UserClassDiagram :> ClassDiagram {
		filter not (as KerML::Element).isLibraryElement;
	}

	/* control: the original definition, expected to leak AggregationKind */
	view classesWithLeak : ClassDiagram {
		expose OnlineStoreDomain::*;
	}

	view classesFiltered : UserClassDiagram {
		expose OnlineStoreDomain::*;
	}

	view componentsFiltered : ComponentDiagram {
		expose OnlineStoreArchitecture::*;
		filter not (as KerML::Element).isLibraryElement;
	}
}
