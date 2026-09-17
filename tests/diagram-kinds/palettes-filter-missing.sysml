/* Fixture for tools/check_diagram_kinds.py: a palette for the probe kind, the filter does not select a shown keyword */
package PalettesFixtureFilterMissing {
	doc
	/*
	Fixture: a palette whose buttons the checker compares with the diagram-kind model.
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
		package signalTemplate { #signal item def; }
	}
	part def ProbePalette :> GeneralPalette {
		doc /* The palette under test. */
		@PaletteForDiagramKind { kind = UML3DiagramKinds::probeKind meta KerML::Type; }
		part probeCategory {
			doc /* Buttons. */
			part classButton {
				doc /* Creates a class. */
				perform action { in ref = (UML3ElementTemplates::classTemplate meta KerML::Package).ownedElement; }
			}
		}
	}
}
