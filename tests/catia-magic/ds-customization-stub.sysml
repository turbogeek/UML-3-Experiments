/* TEST STUB, not the vendor library: the names of the 3DS SysML Customization library (DS_UIComponents, DS_Views)
 * that customization/catia-magic uses, declared so tools/check_names.py can resolve them outside CATIA Magic.
 * Shapes follow CATIA Magic's own textual notation of the library (experiment E16). Never load this file into
 * CATIA Magic, where the real library is attached. DS_Styles holds the style-sheet names the detail views use. The packages are declared by their short names (DS_Views, not
 * DassaultSystemesViews) because the ANTLR validator rejects short names on packages. Add a name here when the
 * customization starts using it. */
library package DS_UIComponents {
	package CoreUIComponents {
		private import ScalarValues::*;
		private import Metaobjects::*;
		package Operations {
			abstract action def Operation;
			abstract action def PaletteOperation :> Operation;
			abstract action def DialogOperation :> Operation;
			action def OperationFromCode :> PaletteOperation { in actionId [0..1] : String; }
			action def OperationFromTemplate :> PaletteOperation, DialogOperation { in element [0..1] : Metaobject; }
			action def OperationByMetaclass :> DialogOperation { in elementMetaclass [0..1] : Metaobject; }
		}
		package Components {
			abstract part def AbstractItem {
				attribute label : String;
				attribute description : String;
			}
			abstract part def Item :> AbstractItem {
				perform action operation [0..1] : Operations::Operation;
			}
			abstract part def ItemsCategory :> AbstractItem {
				attribute isCollapsed : Boolean;
				attribute hasVisibleLabels : Boolean;
				part abstractItems [*] : AbstractItem;
			}
			abstract part def Component {
				part itemCategories [*] : ItemsCategory;
			}
		}
		package Palette {
			private import Components::*;
			abstract part def AbstractButton;
			enum def SymbolicRepresentationKind { naryShape; path; shapeOnBorder; shape; }
			part def Button :> Item, AbstractButton {
				attribute representation : SymbolicRepresentationKind [0..1];
			}
			part def ButtonsCategory :> ItemsCategory, AbstractButton {
				part abstractButtons : AbstractButton :>> abstractItems;
				ref part focusedButton [0..1] : Button;
			}
			part def Palette :> Component {
				part buttonCategories [*] : ButtonsCategory :>> itemCategories;
			}
		}
		package Dialogs {
			private import Components::*;
			part def DialogItem :> Item;
			part def DialogItemsCategory :> ItemsCategory;
			abstract part def Dialog :> Component {
				attribute actionName : String;
			}
			part def ElementCreationDialog :> Dialog;
			part def ViewCreationDialog :> Dialog;
			part def ViewCreationDialogConfiguration {
				part activeViewCreationDialog [0..1] : ViewCreationDialog;
			}
		}
	}
	package UIComponents {
		private import CoreUIComponents::Dialogs::*;
		part def SysMLViewCreationDialog :> ViewCreationDialog;
	}
}

library package DS_Views {
	private import DS_UIComponents::CoreUIComponents::Palette::*;
	package CoreViews {
		abstract view def Visualization;
		abstract view def <sv> 'Symbolic View' :> Visualization {
			part palette [0..1] : Palette;
		}
		abstract view def <bsv> 'Base Symbolic View' :> sv {
			part baseViewPalette : ViewPalettes::BasePalette :>> palette;
		}
		/* Tables. The standard rendering Views::asElementTable carries its columns in columnView but cannot say
		 * how a cell is drawn, so CATIA Magic adds column views and cell renderings; 'UML3 Class Table' uses
		 * them (I-44). */
		rendering def TableCellRendering {
			calc getValue { in rowElement [0..1]; }
		}
		rendering asTableCell : TableCellRendering;
		rendering def StringCellRendering :> TableCellRendering;
		view def ColumnView {
			attribute isMultiline [0..1] : ScalarValues::Boolean;
		}
		view def ColumnByFeatureView :> ColumnView {
			ref item columnFeature [0..1];
		}
		view def ColumnByExpressionView :> ColumnView {
			render asTableCell;
		}
		rendering asTable :> Views::asElementTable {
			view column : ColumnView :> columnView;
		}
		abstract view def <bgv> 'Base Grid View' :> Visualization;
		abstract view def <bt> 'Base Table' :> bgv {
			render asTable;
		}
	}
	package ViewPalettes {
		part def BasePalette :> Palette {
			part selectionCategory : ButtonsCategory :> buttonCategories;
			part toolsCategory : ButtonsCategory :> buttonCategories;
			part commonCategory : ButtonsCategory :> buttonCategories;
		}
		part def GeneralPalette :> BasePalette {
			part itemsPortsAttributesCategory : ButtonsCategory :> buttonCategories;
			part connectorsCategory : ButtonsCategory :> buttonCategories;
			part specializationsCategory : ButtonsCategory :> buttonCategories;
			part otherRelationshipsCategory : ButtonsCategory :> buttonCategories;
			part actionsCategory : ButtonsCategory :> buttonCategories;
			part otherActionsCategory : ButtonsCategory :> buttonCategories;
			part statesCategory : ButtonsCategory :> buttonCategories;
			part casesCategory : ButtonsCategory :> buttonCategories;
			part requirementsConstraintsCategory : ButtonsCategory :> buttonCategories;
		}
		part def InterconnectionPalette :> GeneralPalette;
		package CodeActionIdentifiers {
			private import ScalarValues::*;
			attribute subclassifactionAction : String = "ADD_SUBCLASSIFICATION";
			attribute dependencyAction : String = "ADD_DEPENDENCY";
			attribute partAction : String = "ADD_PART";
			attribute partDefAction : String = "ADD_PART_DEF";
			attribute portAction : String = "ADD_PORT";
			attribute portDefAction : String = "ADD_PORT_DEF";
			attribute itemDefAction : String = "ADD_ITEM_DEF";
			attribute attributeAction : String = "ADD_ATTRIBUTE";
			attribute attributeDefAction : String = "ADD_ATTRIBUTE_DEF";
			attribute enumDefAction : String = "ADD_ENUM_DEF";
			attribute connectionAction : String = "ADD_CONNECTION";
			attribute connectionDefAction : String = "ADD_CONNECTION_DEF";
			attribute interfaceAction : String = "ADD_INTERFACE";
			attribute allocationAction : String = "ADD_ALLOCATION";
			attribute flowAction : String = "ADD_FLOW";
			attribute bindAction : String = "ADD_BIND";
		}
	}
}

library package DS_Styles {
	private import ScalarValues::*;
	private import Metaobjects::*;
	package CoreStylesComponents {
		package KerMLStyles {
			view def SymbolStyle;
			view def ShapeStyle :> SymbolStyle;
			view def ElementStyle;
			view def ElementTrimmableTextStyle :> ElementStyle;
			view def TypeStyle :> ElementTrimmableTextStyle;
			view def BasicFeatureStyle :> TypeStyle;
			view def FeatureStyle :> BasicFeatureStyle;
			view def CompartmentStyle {
				attribute showCompartment : Boolean default true;
				attribute showFullText : Boolean default true;
			}
			view def BasicFeatureCompartmentStyle :> CompartmentStyle, BasicFeatureStyle;
			view def FeatureCompartmentStyle :> BasicFeatureCompartmentStyle, FeatureStyle;
		}
		package SysMLStyles {
			private import KerMLStyles::*;
			view def MetadataCompartmentStyle :> CompartmentStyle, ElementTrimmableTextStyle;
			view def FeaturesOfMetadataCompartmentStyle :> CompartmentStyle, ElementTrimmableTextStyle;
			view def DocumentationCompartmentStyle :> CompartmentStyle, ElementTrimmableTextStyle;
			view def AttributesCompartmentStyle :> FeatureCompartmentStyle;
			view def ParametersCompartmentStyle :> FeatureCompartmentStyle;
			view def ItemsCompartmentStyle :> FeatureCompartmentStyle;
			view def ActionsCompartmentStyle :> FeatureCompartmentStyle;
			view def PartsCompartmentStyle :> FeatureCompartmentStyle;
			view def PortsCompartmentStyle :> FeatureCompartmentStyle;
			view def EndsCompartmentStyle :> FeatureCompartmentStyle;
		}
		package Predicates {
			abstract part def Condition;
			part def ByElementMetaclassCondition :> Condition {
				ref item elementMetaclass [1..*] : Metaobject;
			}
			part def ByMetadataAnnotationCondition :> Condition {
				ref item annotatingMetadataType [1..*] : Metaobject;
			}
			part def ByDiagramTypeCondition :> Condition {
				ref item diagramType [1..*] : Metaobject;
			}
		}
		part def StyleSheet {
			private import Predicates::*;
			part styleSheetCondition : Condition;
			part rule [*] {
				part condition : Condition;
				part style;
			}
		}
	}
	package StyleSheets {
		private import CoreStylesComponents::*;
		private import CoreStylesComponents::SysMLStyles::*;
		part def DefaultStyleSheet :> StyleSheet;
		package CompartmentVisibilityDefinitions {
			private import CoreStylesComponents::SysMLStyles::*;
			part def UsagesAndDefCompartments {
				part metadataCompartment : MetadataCompartmentStyle;
				part featuresOfMetadataCompartment : FeaturesOfMetadataCompartmentStyle;
				part documentationCompartment : DocumentationCompartmentStyle;
				part attributesCompartment : AttributesCompartmentStyle;
				part parametersCompartment : ParametersCompartmentStyle;
				part itemsCompartment : ItemsCompartmentStyle;
				part actionsCompartment : ActionsCompartmentStyle;
				part partsCompartment : PartsCompartmentStyle;
				part portsCompartment : PortsCompartmentStyle;
				part endsCompartment : EndsCompartmentStyle;
			}
		}
	}
}
