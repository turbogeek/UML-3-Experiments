/* Experiment E17e probe (not a library): the component view carries two inherited renderings that are both named
 * asInterconnectionDiagram (CATIA Magic's 'Symbolic View' and UML3Views::ComponentDiagram). Can one owned rendering
 * redefine both by qualified name? Load after the UML3 libraries, customization/catia-magic and example 02.
 * Prediction: tests/cameo-experiments/e17-predictions.json (P19), recorded before the run. */
package UML3ProbeComponentRendering {
	private import DS_Views::CoreViews::*;
	private import UML3CatiaMagic::*;

	view def E17V15 :> bsv, UML3Views::ComponentDiagram {
		render rendering nestedRendering :>> DS_Views::CoreViews::'Symbolic View'::asInterconnectionDiagram,
			UML3Views::ComponentDiagram::asInterconnectionDiagram;
		part p15 : UML3ClassPalette :>> baseViewPalette;
	}

	view v15 : E17V15 { expose OnlineStoreArchitecture::*; }
}
