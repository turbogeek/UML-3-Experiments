/* Fixture for tools/check_diagram_kinds.py: a definition-and-usage menu for a kind without defaultForm */
package PalettesFixtureFocusUndefined {
	doc
	/*
	Fixture: a palette whose class menu offers both forms and focuses the definition, but the kind has no
	defaultForm that says which form comes first.
	Contents:
	- ProbePalette: the palette under test; UML3ElementTemplates: its templates.
	*/
	private import UML3Core::*;
	metadata def PaletteForDiagramKind {
		doc /* Links a palette to its diagram kind. */
		attribute kind : KerML::Type { doc /* The kind. */ }
	}
	part def GeneralPalette { doc /* Stands in for the vendor palette. */ }
	package UML3ElementTemplates {
		doc
		/*
		Templates of the probe palette.
		Contents: one template package per button.
		*/
		package classTemplate { #classType item def; }
		package classUsageTemplate { #classType item; }
	}
	part def ProbePalette :> GeneralPalette {
		doc /* The palette under test. */
		@PaletteForDiagramKind { kind = UML3DiagramKinds::probeKind meta KerML::Type; }
		part probeCategory {
			doc /* Buttons. */
			part classMenu {
				doc /* A class, as a definition or a usage. */
				part classUsageButton {
					doc /* Creates a class usage. */
					perform action { in ref = (UML3ElementTemplates::classUsageTemplate meta KerML::Package).ownedElement; }
				}
				part classDefButton {
					doc /* Creates a class definition. */
					perform action { in ref = (UML3ElementTemplates::classTemplate meta KerML::Package).ownedElement; }
				}
				attribute focusedButton default classDefButton { doc /* Which form comes first is not modeled for this kind. */ }
			}
		}
	}
}
