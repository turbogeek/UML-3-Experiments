/* Experiment E17b probe (not a library): which form of a custom symbolic view definition gets a UML3 palette in
 * CATIA Magic, keeps a tree rendering and validates. Load after the UML3 libraries, customization/catia-magic and
 * example 01. Predictions: tests/cameo-experiments/e17-predictions.json (P9-P13), recorded before the run. */
package UML3ProbeViewDefVariants {
	private import DS_Views::CoreViews::*;
	private import UML3CatiaMagic::*;

	/* V0: UML3 view definition first (the E17a form). */
	view def E17V0 :> UML3Views::ClassDiagram, bsv { part p0 : UML3ClassPalette :>> baseViewPalette; }
	/* V1: bsv first, inherits the renderings of both generals. */
	view def E17V1 :> bsv, UML3Views::ClassDiagram { part p1 : UML3ClassPalette :>> baseViewPalette; }
	/* V2: V1 plus an owned tree rendering. */
	view def E17V2 :> bsv, UML3Views::ClassDiagram {
		render Views::asTreeDiagram;
		part p2 : UML3ClassPalette :>> baseViewPalette;
	}
	/* V3: bsv only, own filter and an owned tree rendering. */
	view def E17V3 :> bsv {
		filter @UML3Core::classType or @UML3Core::interfaceType or @UML3Core::DataTypeKind or @SysML::EnumerationDefinition;
		render Views::asTreeDiagram;
		part p3 : UML3ClassPalette :>> baseViewPalette;
	}
	/* V4: bsv first with the detail view (no rendering of its own). */
	view def E17V4 :> bsv, UML3Views::ClassDetailDiagram { part p4 : UML3ClassPalette :>> baseViewPalette; }
	/* V5: bsv only, own filter, the inherited interconnection rendering redefined by a tree rendering. */
	view def E17V5 :> bsv {
		filter @UML3Core::classType or @UML3Core::interfaceType or @UML3Core::DataTypeKind or @SysML::EnumerationDefinition;
		render rendering treeRendering :>> asInterconnectionDiagram :> Views::asTreeDiagram;
		part p5 : UML3ClassPalette :>> baseViewPalette;
	}
	/* V6: bsv first with the UML3 view definition, one owned rendering redefining both inherited renderings. */
	view def E17V6 :> bsv, UML3Views::ClassDiagram {
		render rendering treeRendering :>> asInterconnectionDiagram, asTreeDiagram;
		part p6 : UML3ClassPalette :>> baseViewPalette;
	}

	view v0 : E17V0 { expose OnlineStoreDomain::*; }
	view v1 : E17V1 { expose OnlineStoreDomain::*; }
	view v2 : E17V2 { expose OnlineStoreDomain::*; }
	view v3 : E17V3 { expose OnlineStoreDomain::*; }
	view v4 : E17V4 { expose OnlineStoreDomain::*; }
	view v5 : E17V5 { expose OnlineStoreDomain::*; }
	view v6 : E17V6 { expose OnlineStoreDomain::*; }
}
