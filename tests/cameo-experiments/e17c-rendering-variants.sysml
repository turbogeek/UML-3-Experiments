/* Experiment E17c probe (not a library): removing or replacing the rendering that DS_Views::CoreViews::bsv inherits
 * from 'Symbolic View' in a UML3 view definition. Load after the UML3 libraries, customization/catia-magic and
 * example 01. Predictions: tests/cameo-experiments/e17-predictions.json (P14, P15), recorded before the run. */
package UML3ProbeRenderingVariants {
	private import DS_Views::CoreViews::*;
	private import UML3CatiaMagic::*;

	/* V7: detail view; the inherited interconnection rendering is removed (multiplicity 0). */
	view def E17V7 :> bsv, UML3Views::ClassDetailDiagram {
		render rendering :>> asInterconnectionDiagram [0];
		part p7 : UML3ClassPalette :>> baseViewPalette;
	}
	/* V9: compact view; one owned rendering redefines both inherited renderings, tree first. */
	view def E17V9 :> bsv, UML3Views::ClassDiagram {
		render rendering compactRendering :>> asTreeDiagram, asInterconnectionDiagram;
		part p9 : UML3ClassPalette :>> baseViewPalette;
	}

	view v7 : E17V7 { expose OnlineStoreDomain::*; }
	view v9 : E17V9 { expose OnlineStoreDomain::*; }
}
