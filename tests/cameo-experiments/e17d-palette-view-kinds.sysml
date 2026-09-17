/* Experiment E17d probe (not a library): the E17V9 form (one owned rendering redefining the inherited ones) applied
 * to the other UML3 view kinds, and the component view, whose two inherited renderings are both
 * asInterconnectionDiagram. Load after the UML3 libraries, customization/catia-magic and examples 01-04.
 * Predictions: tests/cameo-experiments/e17-predictions.json (P16-P18), recorded before the run. */
package UML3ProbePaletteViewKinds {
	private import DS_Views::CoreViews::*;
	private import UML3CatiaMagic::*;

	/* V10: component view, no owned rendering (both inherited renderings are asInterconnectionDiagram). */
	view def E17V10 :> bsv, UML3Views::ComponentDiagram { part p10 : UML3ClassPalette :>> baseViewPalette; }
	/* V10b: component view, the inherited rendering redefined by name although two inherited features share it. */
	view def E17V10b :> bsv, UML3Views::ComponentDiagram {
		render rendering nestedRendering :>> asInterconnectionDiagram;
		part p10b : UML3ClassPalette :>> baseViewPalette;
	}
	/* V11-V14: the other tree-rendered UML3 view definitions in the E17V9 form. */
	view def E17V11 :> bsv, UML3Views::PackageDiagram {
		render rendering compactRendering :>> asTreeDiagram, asInterconnectionDiagram;
		part p11 : UML3ClassPalette :>> baseViewPalette;
	}
	view def E17V12 :> bsv, UML3Views::DeploymentDiagram {
		render rendering compactRendering :>> asTreeDiagram, asInterconnectionDiagram;
		part p12 : UML3ClassPalette :>> baseViewPalette;
	}
	view def E17V13 :> bsv, UML3Views::EntityRelationshipDiagram {
		render rendering compactRendering :>> asTreeDiagram, asInterconnectionDiagram;
		part p13 : UML3ClassPalette :>> baseViewPalette;
	}
	view def E17V14 :> bsv, UML3Views::MessageSchemaView {
		render rendering compactRendering :>> asTreeDiagram, asInterconnectionDiagram;
		part p14 : UML3ClassPalette :>> baseViewPalette;
	}

	view v10 : E17V10 { expose OnlineStoreArchitecture::*; }
	view v10b : E17V10b { expose OnlineStoreArchitecture::*; }
	view v11 : E17V11 { expose OnlineStoreDomain::**; }
	view v12 : E17V12 { expose OnlineStoreArchitecture::**; }
	view v13 : E17V13 { expose OnlineStoreDatabase::*; }
	view v14 : E17V14 { expose OnlineStoreMessaging::*; }
}
