library package UML3CatiaMagic {
	doc
	/*
	UML3CatiaMagic: the CATIA Magic customization of UML3. It turns the UML3 diagram kinds into CATIA Magic
	symbolic views whose palettes create UML3 elements: a palette button copies a template that already
	carries the UML3 keyword, so a class drawn from the palette is a #classType item def from the start.

	This package is tool specific. The UML3 libraries stay tool neutral; this package builds on them and on
	the 3DS SysML Customization library (DS_Views, DS_UIComponents), which CATIA Magic attaches to SysML v2
	projects. Load it after the UML3 libraries. CATIA Magic reads palettes when a project opens, so reload
	the project after loading or changing it.

	Usage: type a view by one of the view definitions below instead of the UML3Views definition it
	specializes; the view keeps the UML3 filters and rendering and gains the UML3 palette.
	  view domainClasses : UML3CatiaMagic::'UML3 Class Diagram' { expose OnlineStoreDomain::*; }

	Contents:
	- UML3ElementTemplates: one template package per palette button, each owning the element the button copies.
	- UML3ClassPalette: the General View palette plus the UML3 Classifiers and UML3 Relationships categories.
	- 'UML3 Class Diagram', 'UML3 Class Detail Diagram': UML3Views::ClassDiagram and ClassDetailDiagram with
	  the UML3 class palette.
	References: CATIA Magic SysML v2 Plugin 2026x R1 'Custom symbolic view definitions'; E16; E17;
	UML3Views::ClassDiagram.
	*/

	private import DS_UIComponents::CoreUIComponents::Palette::*;
	private import DS_UIComponents::CoreUIComponents::Operations::*;
	private import DS_Views::CoreViews::*;
	private import DS_Views::ViewPalettes::*;
	private import DS_Views::ViewPalettes::CodeActionIdentifiers::*;
	private import UML3Core::*;

	comment TemplateDesign about UML3ElementTemplates, UML3ClassPalette
		/*
		Templated buttons. A button whose operation is OperationFromTemplate copies the one element owned by
		its template package into the model, with that element's keywords, ends and values. This is the
		mechanism CATIA Magic's own derivation buttons use (DS_Views::ViewPalettes::ElementTemplates), and
		the button selects the element with '(template meta KerML::Package).ownedElement'.
		Template packages therefore own exactly one element and no documentation: a doc would be a second
		owned element and would be copied into every created element. Template elements are unnamed, so
		CATIA Magic lets the user name the new element. A template for a dependency also owns the two
		definitions the dependency needs; its button selects the dependency with 'as SysML::Dependency'.
		References: CATIA Magic SysML v2 Plugin 2026x R1 'Creating templates for custom buttons'; E16.
		*/

	package UML3ElementTemplates {
		doc
		/*
		The elements that UML3 palette buttons copy, one template package per button. Template packages
		and their elements carry no documentation (see TemplateDesign).

		Contents:
		- classTemplate, interfaceTypeTemplate, dataTypeTemplate: classifier templates.
		- associationTemplate: a binary #association connection def.
		- usesTemplate: a #uses dependency between two placeholder definitions.
		*/
		package classTemplate { #classType item def; }
		package interfaceTypeTemplate { #interfaceType item def; }
		package dataTypeTemplate { #dataType attribute def; }
		package associationTemplate {
			#association connection def {
				end [0..*] ref;
				end [0..*] ref;
			}
		}
		package usesTemplate {
			item def Client;
			item def Supplier;
			#uses dependency from Client to Supplier;
		}
	}

	part def UML3ClassPalette :> GeneralPalette {
		doc
		/*
		Palette of UML3 class diagrams: the CATIA Magic General View palette with two UML3 categories in
		front. UML3 Classifiers creates classes, interfaces, data types and enumerations; UML3 Relationships
		creates associations, generalizations and #uses dependencies. The behavior categories of the
		General View palette are removed, because class diagrams show structure.

		Usage: 'part uml3ClassPalette : UML3ClassPalette :>> baseViewPalette;' in a view definition that
		specializes DS_Views::CoreViews::bsv.
		References: DS_Views::ViewPalettes::GeneralPalette; UML 2.5.1 Class diagram; E17.
		*/
		part :>> selectionCategory;
		part :>> toolsCategory;
		part :>> commonCategory;
		part uml3ClassifiersCategory : ButtonsCategory :> buttonCategories {
			doc /* UML3 classifiers: the elements a class diagram is made of. */
			attribute :>> isCollapsed default false;
			attribute :>> hasVisibleLabels default true;
			attribute :>> label default "UML3 Classifiers";
			attribute :>> description default "UML3 classes, interfaces, data types and enumerations";
			part classButton : Button :> abstractButtons {
				doc /* Creates a UML3 Class: a #classType item def. */
				attribute :>> label = "class";
				attribute :>> description = "#classType item def: a UML3 Class";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::classTemplate meta KerML::Package).ownedElement;
				}
			}
			part interfaceTypeButton : Button :> abstractButtons {
				doc /* Creates a UML3 InterfaceType: an #interfaceType item def. */
				attribute :>> label = "interface";
				attribute :>> description = "#interfaceType item def: a UML3 InterfaceType";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::interfaceTypeTemplate meta KerML::Package).ownedElement;
				}
			}
			part dataTypeButton : Button :> abstractButtons {
				doc /* Creates a UML3 DataType: a #dataType attribute def. */
				attribute :>> label = "data type";
				attribute :>> description = "#dataType attribute def: a UML3 DataType";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::dataTypeTemplate meta KerML::Package).ownedElement;
				}
			}
			part enumerationButton : Button :> abstractButtons {
				doc /* Creates an enum def, which UML3 uses as the UML Enumeration without a keyword. */
				perform action : OperationFromCode :>> operation { in ref = enumDefAction; }
			}
		}
		part uml3RelationshipsCategory : ButtonsCategory :> buttonCategories {
			doc /* UML3 relationships between classifiers. */
			attribute :>> isCollapsed default false;
			attribute :>> hasVisibleLabels default true;
			attribute :>> label default "UML3 Relationships";
			attribute :>> description default "UML3 associations, generalizations and dependencies";
			part associationButton : Button :> abstractButtons {
				doc /* Creates a UML3 Association: a binary #association connection def. */
				attribute :>> label = "association";
				attribute :>> description = "#association connection def: a binary UML3 Association";
				attribute :>> representation = SymbolicRepresentationKind::path;
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::associationTemplate meta KerML::Package).ownedElement;
				}
			}
			part generalizationButton : Button :> abstractButtons {
				doc /* Creates a subclassification, the UML Generalization between definitions. */
				perform action : OperationFromCode :>> operation { in ref = subclassifactionAction; }
			}
			part usesButton : Button :> abstractButtons {
				doc /* Creates a #uses dependency (UML «use»). */
				attribute :>> label = "uses";
				attribute :>> description = "#uses dependency: the client needs the supplier (UML «use»)";
				attribute :>> representation = SymbolicRepresentationKind::path;
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::usesTemplate meta KerML::Package).ownedElement as SysML::Dependency;
				}
			}
		}
		part :>> actionsCategory [0];
		part :>> otherActionsCategory [0];
		part :>> statesCategory [0];
		part :>> casesCategory [0];
	}

	view def <UML3ClassDiagram> 'UML3 Class Diagram' :> UML3Views::ClassDiagram, bsv {
		doc
		/*
		UML3Views::ClassDiagram as a CATIA Magic symbolic view with the UML3 class palette: the same filters
		and compact tree rendering, and palette buttons that create UML3 keyword elements.

		Usage: view domainClasses : UML3CatiaMagic::'UML3 Class Diagram' { expose OnlineStoreDomain::*; }
		References: UML3Views::ClassDiagram; DS_Views::CoreViews::bsv; E17.
		*/
		part uml3ClassPalette : UML3ClassPalette :>> baseViewPalette {
			doc /* The palette of this view: the UML3 class palette in place of the Base Symbolic View palette. */
		}
	}

	view def <UML3ClassDetailDiagram> 'UML3 Class Detail Diagram' :> UML3Views::ClassDetailDiagram, bsv {
		doc
		/*
		UML3Views::ClassDetailDiagram as a CATIA Magic symbolic view with the UML3 class palette.

		Usage: view domainClassDetails : UML3CatiaMagic::'UML3 Class Detail Diagram' { expose OnlineStoreDomain::*; }
		References: UML3Views::ClassDetailDiagram; DS_Views::CoreViews::bsv; E17.
		*/
		part uml3ClassDetailPalette : UML3ClassPalette :>> baseViewPalette {
			doc /* The palette of this view: the UML3 class palette in place of the Base Symbolic View palette. */
		}
	}
}
