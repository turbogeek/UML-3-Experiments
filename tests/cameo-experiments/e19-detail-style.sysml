/* Experiment E19 probe (not a library): can a style sheet give a palette-carrying view the compartments that a
 * rendered view suppresses (issue I-36)? Load after the UML3 libraries, customization/catia-magic and example 01.
 * Predictions: tests/cameo-experiments/e19-predictions.json (P1-P5), recorded before the run. */
package UML3ProbeDetailStyle {
	private import DS_Views::CoreViews::*;
	private import DS_Styles::CoreStylesComponents::*;
	private import DS_Styles::CoreStylesComponents::Predicates::*;
	private import DS_Styles::StyleSheets::CompartmentVisibilityDefinitions::*;
	private import DS_Styles::StyleSheets::*;
	private import UML3CatiaMagic::*;

	/* A style sheet that turns the documentation and attributes compartments on for every definition. */
	part def UML3ProbeDetailStyleSheet :> DefaultStyleSheet {
		part uml3DetailRule :> rule {
			part :>> condition : ByElementMetaclassCondition {
				ref item :>> elementMetaclass = SysML::Definition meta KerML::Metaclass;
			}
			view :>> style : UsagesAndDefCompartments {
				part :>> documentationCompartment {
					attribute :>> showCompartment default true;
				}
				part :>> attributesCompartment {
					attribute :>> showCompartment default true;
				}
			}
		}
	}

	/* A detail view with the UML3 class palette and that style sheet. */
	view def E19V1 :> bsv, UML3Views::ClassDetailDiagram {
		part probeStyle : UML3ProbeDetailStyleSheet :>> explicitlyAppliedStyleSheets;
		part probePalette : UML3ClassPalette :>> baseViewPalette;
	}

	view v19 : E19V1 { expose OnlineStoreDomain::*; }
}
