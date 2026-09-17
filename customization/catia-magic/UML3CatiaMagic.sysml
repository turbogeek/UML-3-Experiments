library package UML3CatiaMagic {
	doc
	/*
	UML3CatiaMagic: the CATIA Magic customization of UML3. It turns the UML3 diagram kinds into CATIA Magic
	symbolic views whose palettes create UML3 elements: a palette button copies a template that already
	carries the UML3 keyword, so a class drawn from the palette is a #classType item def from the start.

	This package is tool specific. The UML3 libraries stay tool neutral; this package builds on them and on
	the 3DS SysML Customization library (DS_Views, DS_UIComponents), which CATIA Magic attaches to SysML v2
	projects. Load it after the UML3 libraries.

	Usage: type a view by one of the view definitions below instead of the UML3Views definition it
	specializes; the view keeps the UML3 filters and content and gains the UML3 palette. The palettes appear
	after CATIA Magic rebuilds its customization model, which happens when the project is reloaded.
	  view domainClasses : UML3CatiaMagic::'UML3 Class Diagram' { expose OnlineStoreDomain::*; }

	Contents:
	- UML3ElementTemplates: one template package per palette button, each owning the element the button copies.
	- UML3PackagePalette, UML3ClassPalette, UML3ComponentPalette, UML3DeploymentPalette, UML3DataPalette,
	  UML3MessagingPalette: the CATIA Magic General View palette with the UML3 categories of one diagram kind.
	- 'UML3 Package Diagram', 'UML3 Class Diagram', 'UML3 Component Diagram', 'UML3 Deployment Diagram',
	  'UML3 Entity Relationship Diagram', 'UML3 Message Schema View': the UML3Views definitions with those palettes.
	- UML3ViewTemplates and UML3ViewCreationDialog: the Create View commands for those view definitions.
	- PaletteForDiagramKind: links each palette to its UML3DiagramKinds kind, which is what keeps the
	  buttons and the view filters in step (checked by tools/check_diagram_kinds.py).
	References: CATIA Magic SysML v2 Plugin 2026x R1 'Custom symbolic view definitions' and 'Custom View
	Creation dialog'; E16; E17; UML3Views.
	*/

	private import DS_UIComponents::CoreUIComponents::Palette::*;
	private import DS_UIComponents::CoreUIComponents::Operations::*;
	private import DS_UIComponents::CoreUIComponents::Dialogs::*;
	private import DS_Views::CoreViews::*;
	private import DS_Views::ViewPalettes::*;
	private import DS_Views::ViewPalettes::CodeActionIdentifiers::*;
	private import UML3Core::*;
	private import UML3Components::*;
	private import UML3Data::*;
	private import UML3Messaging::*;

	comment TemplateDesign about UML3ElementTemplates, UML3ClassPalette
		/*
		Templated buttons. A button whose operation is OperationFromTemplate copies the one element owned by
		its template package into the model, with that element's keywords, ends and values. This is the
		mechanism CATIA Magic's own derivation buttons use (DS_Views::ViewPalettes::ElementTemplates), and
		the button selects the element with '(template meta KerML::Package).ownedElement'.
		Template packages therefore own exactly one element and no documentation: a doc would be a second
		owned element and would be copied into every created element. Template elements are unnamed, so
		CATIA Magic lets the user name the new element. A template for a dependency refers to the two
		placeholder definitions Client and Supplier, and its button selects the dependency with
		'as SysML::Dependency'. A connector template owns two placeholder ends as well, because a connector
		that is not abstract must have two related features (validateConnectorRelatedFeatures), and its
		button selects the connector with 'as SysML::ConnectionUsage' or 'as SysML::AllocationUsage'. A flow
		template needs directed ends, so it owns two placeholder parts with UML3Messaging ports and flows
		between their message features; undirected placeholders are not related features (E17, I-36).
		Verified in E17: every templated button resolves to its template element and keyword (class to an
		item definition with ClassMetadata, data type to an attribute definition with DataTypeMetadata,
		association to a connection definition with AssociationMetadata, uses to a dependency with
		UsesDependency).
		References: CATIA Magic SysML v2 Plugin 2026x R1 'Creating templates for custom buttons'; E16; E17.
		*/

	comment ViewDefinitionDesign about 'UML3 Class Diagram', 'UML3 Component Diagram'
		/*
		Why the view definitions look the way they do (experiment E17).
		1. The DS view definition comes first. CATIA Magic builds its customization model from
		   DS_Views::CoreViews::Visualization downwards and keeps a view definition only when its FIRST
		   general type is the one above it, so a definition that lists a UML3 view first is ignored and its
		   views fall back to the General View palette.
		2. One rendering, which redefines the inherited ones. 'Base Symbolic View' inherits
		   'render asInterconnectionDiagram' from 'Symbolic View', and the UML3 view definitions bring their
		   own rendering, which would give a view definition two renderers
		   (validateViewDefinitionOnlyOneViewRendering). The owned rendering here redefines both, so exactly
		   one remains. Where both inherited renderings have the same name (the component view) the
		   redefinition names them by qualified name.
		3. No detail views. A palette needs a 'Base Symbolic View' descendant, and such a view is always
		   rendered as a tree or nested diagram, never with the full compartments of an unrendered view
		   (E17: removing the rendering does not change that). The detail views of UML3Views therefore stay
		   tool neutral and use the General View palette.
		References: SysML 8.2.2.26; E17.
		*/

	metadata def PaletteForDiagramKind {
		doc
		/*
		Links a UML3 palette to the diagram kind whose 'creates' keywords it offers
		(UML3DiagramKinds). tools/check_diagram_kinds.py reads it and reports a palette whose buttons do not
		match the keywords of its kind, so the model and the palettes cannot drift apart (issue I-35).

		Usage: '@PaletteForDiagramKind { kind = UML3DiagramKinds::classDiagram meta KerML::Type; }' in the
		body of a palette definition.
		References: UML3DiagramKinds; docs/DESIGN.md issue I-35.
		*/
		attribute kind : KerML::Type {
			doc /* The UML3DiagramKinds part for this palette, as a metaobject. */
		}
	}

	package UML3ElementTemplates {
		doc
		/*
		The elements that UML3 palette buttons copy, one template package per button. Template packages
		and their elements carry no documentation (see TemplateDesign).

		Contents:
		- Client, Supplier: the placeholder definitions that dependency templates connect.
		- Package and layer templates; classifier, feature and relationship templates of the class diagram.
		- Component, deployment, data and messaging templates, including the message flow templates.
		*/
		item def Client {
			doc /* Placeholder for the client of a dependency template; the diagram replaces it with the element drawn from. */
		}
		item def Supplier {
			doc /* Placeholder for the supplier of a dependency template; the diagram replaces it with the element drawn to. */
		}

		package packageTemplate { package; }
		package layerPackageTemplate { #layer package; }

		package classTemplate { #classType item def; }
		package activeClassTemplate { #activeClass part def; }
		package interfaceTypeTemplate { #interfaceType item def; }
		package dataTypeTemplate { #dataType attribute def; }
		package signalTemplate { #signal item def; }
		package exceptionTypeTemplate { #exceptionType item def; }
		package operationTemplate { #operation action; }
		package queryTemplate { #query calc; }
		package constructorTemplate { #constructor action; }
		package associationTemplate {
			#association connection def {
				end [0..*] ref;
				end [0..*] ref;
			}
		}
		package aggregationTemplate {
			#aggregation connection def {
				end [0..*] ref;
				end [0..*] ref;
			}
		}
		package compositionTemplate {
			#composition connection def {
				end [0..*] ref;
				end [0..*] ref;
			}
		}
		package usesTemplate { #uses dependency from Client to Supplier; }
		package realizesTemplate { #realizes dependency from Client to Supplier; }
		package callsTemplate { #calls dependency from Client to Supplier; }
		package createsTemplate { #creates dependency from Client to Supplier; }
		package tracesTemplate { #traces dependency from Client to Supplier; }
		package instantiatesTemplate { #instantiates dependency from Client to Supplier; }

		package componentTemplate { #component part def; }
		package serviceTemplate { #service part def; }
		package subsystemTemplate { #subsystem part def; }
		package servicePortTemplate { #servicePort port def; }
		package providedPortTemplate { #provided port; }
		package requiredPortTemplate { #required port; }
		package assemblyTemplate {
			item required : Client;
			item provided : Supplier;
			#assembly connect required to provided;
		}
		package delegationTemplate {
			item boundary : Client;
			item inner : Supplier;
			#delegation connect boundary to inner;
		}

		package nodeTemplate { #node part def; }
		package deviceTemplate { #device part def; }
		package executionEnvironmentTemplate { #executionEnvironment part def; }
		package artifactTemplate { #artifact item def; }
		package communicationPathTemplate {
			#communicationPath connection def {
				end [0..*] ref;
				end [0..*] ref;
			}
		}
		package deployTemplate {
			item deployed : Client;
			item target : Supplier;
			#deploy allocate deployed to target;
		}
		package manifestTemplate {
			item manifesting : Client;
			item manifested : Supplier;
			#manifest allocate manifesting to manifested;
		}

		package entityTemplate { #entity item def; }
		package aggregateRootTemplate { #aggregateRoot item def; }
		package valueObjectTemplate { #valueObject attribute def; }
		package relationshipTemplate {
			#relationship connection def {
				end [0..*] ref;
				end [0..*] ref;
			}
		}
		package tableTemplate { #table item def; }
		package databaseViewTemplate { #dbView item def; }
		package databaseTemplate { #database part def; }
		package columnTemplate { #column attribute; }
		package primaryKeyTemplate { #primaryKey attribute; }
		package foreignKeyTemplate { ref #foreignKey item; }
		package mapsToTemplate { #mapsTo dependency from Client to Supplier; }

		package messageTypeTemplate { #messageType item def; }
		package commandTemplate { #command item def; }
		package domainEventTemplate { #domainEvent item def; }
		package queryMessageTemplate { #queryMessage item def; }
		package replyTemplate { #reply item def; }
		package documentMessageTemplate { #documentMessage item def; }
		package channelTemplate { #channel part def; }
		package topicTemplate { #topic part def; }
		package queueTemplate { #queue part def; }
		package brokerTemplate { #broker part def; }

		package publishesTemplate {
			part producer { port events : ProducerPort; }
			part channel { port inbound : ConsumerPort; }
			#publishes flow from producer.events.outboundMessages to channel.inbound.inboundMessages;
		}
		package subscribesTemplate {
			part channel { port outbound : ProducerPort; }
			part consumer { port events : ConsumerPort; }
			#subscribes flow from channel.outbound.outboundMessages to consumer.events.inboundMessages;
		}
		package sendsTemplate {
			part sender { port api : RequestReplyPort; }
			part receiver { port api : ~RequestReplyPort; }
			#sends flow from sender.api.request to receiver.api.request;
		}
		package handlesTemplate {
			part handler { port api : ~RequestReplyPort; }
			part requester { port api : RequestReplyPort; }
			#handles flow from handler.api.response to requester.api.response;
		}
	}

	part def UML3PackagePalette :> GeneralPalette {
		doc
		/*
		Palette of UML3 package diagrams: packages, layer packages and dependencies.

		Usage: 'part uml3PackagePalette : UML3PackagePalette :>> baseViewPalette;' in a view definition that
		specializes DS_Views::CoreViews::bsv.
		References: DS_Views::ViewPalettes::GeneralPalette; UML 2.5.1 Package diagram.
		*/
		@PaletteForDiagramKind { kind = UML3DiagramKinds::packageDiagram meta KerML::Type; }
		part uml3PackagesCategory : ButtonsCategory :> buttonCategories {
			doc /* UML3 packages and the dependencies between them. */
			attribute :>> isCollapsed default false;
			attribute :>> hasVisibleLabels default true;
			attribute :>> label default "UML3 Packages";
			attribute :>> description default "UML3 packages, layers and dependencies";
			part packageButton : Button :> abstractButtons {
				doc /* Creates a package. */
				attribute :>> label = "package";
				attribute :>> description = "package: a namespace of model elements";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::packageTemplate meta KerML::Package).ownedElement;
				}
			}
			part layerButton : Button :> abstractButtons {
				doc /* Creates a #layer package, an architecture layer. */
				attribute :>> label = "layer";
				attribute :>> description = "#layer package: an architecture layer (set @Layer values afterwards)";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::layerPackageTemplate meta KerML::Package).ownedElement;
				}
			}
			part usesButton : Button :> abstractButtons {
				doc /* Creates a #uses dependency between packages. */
				attribute :>> label = "uses";
				attribute :>> description = "#uses dependency: the client package needs the supplier package";
				attribute :>> representation = SymbolicRepresentationKind::path;
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::usesTemplate meta KerML::Package).ownedElement as SysML::Dependency;
				}
			}
			part dependencyButton : Button :> abstractButtons {
				doc /* Creates a plain dependency, for a relationship no UML3 keyword describes. */
				perform action : OperationFromCode :>> operation { in ref = dependencyAction; }
			}
		}
		part :>> itemsPortsAttributesCategory { attribute :>> isCollapsed default true; }
		part :>> actionsCategory [0];
		part :>> otherActionsCategory [0];
		part :>> statesCategory [0];
		part :>> casesCategory [0];
		part :>> requirementsConstraintsCategory [0];
	}

	part def UML3ClassPalette :> GeneralPalette {
		doc
		/*
		Palette of UML3 class diagrams: UML3 Classifiers creates classes, active classes, interfaces, data
		types, signals, exceptions and enumerations; UML3 Features creates operations, queries,
		constructors and attributes; UML3 Relationships creates associations, aggregations, compositions,
		generalizations and the dependency keywords. The behavior categories of the General View palette are
		removed, because class diagrams show structure.

		Usage: 'part uml3ClassPalette : UML3ClassPalette :>> baseViewPalette;' in a view definition that
		specializes DS_Views::CoreViews::bsv.
		References: DS_Views::ViewPalettes::GeneralPalette; UML 2.5.1 Class diagram; E17.
		*/
		@PaletteForDiagramKind { kind = UML3DiagramKinds::classDiagram meta KerML::Type; }
		part uml3ClassifiersCategory : ButtonsCategory :> buttonCategories {
			doc /* UML3 classifiers: the boxes of a class diagram. */
			attribute :>> isCollapsed default false;
			attribute :>> hasVisibleLabels default true;
			attribute :>> label default "UML3 Classifiers";
			attribute :>> description default "UML3 classes, interfaces, data types, signals, exceptions and enumerations";
			part classButton : Button :> abstractButtons {
				doc /* Creates a UML3 Class: a #classType item def. */
				attribute :>> label = "class";
				attribute :>> description = "#classType item def: a UML3 Class";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::classTemplate meta KerML::Package).ownedElement;
				}
			}
			part activeClassButton : Button :> abstractButtons {
				doc /* Creates a UML3 ActiveClass: an #activeClass part def with its own thread of control. */
				attribute :>> label = "active class";
				attribute :>> description = "#activeClass part def: a UML3 ActiveClass";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::activeClassTemplate meta KerML::Package).ownedElement;
				}
			}
			part interfaceTypeButton : Button :> abstractButtons {
				doc /* Creates a UML3 InterfaceType: an #interfaceType item def of abstract operations. */
				attribute :>> label = "interface";
				attribute :>> description = "#interfaceType item def: a UML3 InterfaceType";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::interfaceTypeTemplate meta KerML::Package).ownedElement;
				}
			}
			part dataTypeButton : Button :> abstractButtons {
				doc /* Creates a UML3 DataType: a #dataType attribute def, a value without identity. */
				attribute :>> label = "data type";
				attribute :>> description = "#dataType attribute def: a UML3 DataType";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::dataTypeTemplate meta KerML::Package).ownedElement;
				}
			}
			part signalButton : Button :> abstractButtons {
				doc /* Creates a UML3 Signal: a #signal item def, an asynchronous stimulus. */
				attribute :>> label = "signal";
				attribute :>> description = "#signal item def: a UML3 Signal";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::signalTemplate meta KerML::Package).ownedElement;
				}
			}
			part exceptionTypeButton : Button :> abstractButtons {
				doc /* Creates a UML3 ExceptionType: an #exceptionType item def raised by operations. */
				attribute :>> label = "exception";
				attribute :>> description = "#exceptionType item def: a UML3 ExceptionType";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::exceptionTypeTemplate meta KerML::Package).ownedElement;
				}
			}
			part enumerationButton : Button :> abstractButtons {
				doc /* Creates an enum def, which UML3 uses as the UML Enumeration without a keyword. */
				perform action : OperationFromCode :>> operation { in ref = enumDefAction; }
			}
		}
		part uml3FeaturesCategory : ButtonsCategory :> buttonCategories {
			doc /* UML3 features of a classifier: attributes and behavioral features. */
			attribute :>> isCollapsed default false;
			attribute :>> hasVisibleLabels default true;
			attribute :>> label default "UML3 Features";
			attribute :>> description default "UML3 attributes, operations, queries and constructors";
			part attributeButton : Button :> abstractButtons {
				doc /* Creates an attribute usage, the UML3 form of a class attribute. */
				perform action : OperationFromCode :>> operation { in ref = attributeAction; }
			}
			part operationButton : Button :> abstractButtons {
				doc /* Creates a UML3 Operation: an #operation action. */
				attribute :>> label = "operation";
				attribute :>> description = "#operation action: a UML3 Operation of the owning classifier";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::operationTemplate meta KerML::Package).ownedElement;
				}
			}
			part queryButton : Button :> abstractButtons {
				doc /* Creates a UML3 Query: a #query calc that returns a value without changing state. */
				attribute :>> label = "query";
				attribute :>> description = "#query calc: a UML3 Query (no side effects)";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::queryTemplate meta KerML::Package).ownedElement;
				}
			}
			part constructorButton : Button :> abstractButtons {
				doc /* Creates a UML3 Constructor: a #constructor action that returns a new instance. */
				attribute :>> label = "constructor";
				attribute :>> description = "#constructor action: a UML3 Constructor";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::constructorTemplate meta KerML::Package).ownedElement;
				}
			}
		}
		part uml3RelationshipsCategory : ButtonsCategory :> buttonCategories {
			doc /* UML3 relationships between classifiers. */
			attribute :>> isCollapsed default false;
			attribute :>> hasVisibleLabels default true;
			attribute :>> label default "UML3 Relationships";
			attribute :>> description default "UML3 associations, generalizations and dependency keywords";
			part associationButton : Button :> abstractButtons {
				doc /* Creates a UML3 Association: a binary #association connection def. */
				attribute :>> label = "association";
				attribute :>> description = "#association connection def: a binary UML3 Association";
				attribute :>> representation = SymbolicRepresentationKind::path;
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::associationTemplate meta KerML::Package).ownedElement;
				}
			}
			part aggregationButton : Button :> abstractButtons {
				doc /* Creates a UML3 Aggregation: a shared whole-part #aggregation connection def. */
				attribute :>> label = "aggregation";
				attribute :>> description = "#aggregation connection def: a shared whole-part association";
				attribute :>> representation = SymbolicRepresentationKind::path;
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::aggregationTemplate meta KerML::Package).ownedElement;
				}
			}
			part compositionButton : Button :> abstractButtons {
				doc /* Creates a UML3 Composition: an owning whole-part #composition connection def. */
				attribute :>> label = "composition";
				attribute :>> description = "#composition connection def: an owning whole-part association";
				attribute :>> representation = SymbolicRepresentationKind::path;
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::compositionTemplate meta KerML::Package).ownedElement;
				}
			}
			part generalizationButton : Button :> abstractButtons {
				doc /* Creates a subclassification, the UML Generalization between definitions. */
				perform action : OperationFromCode :>> operation { in ref = subclassifactionAction; }
			}
			part dependencyMenu : ButtonsCategory :> abstractButtons {
				doc /* The UML3 dependency keywords, one button each. */
				part usesButton : Button :> abstractButtons {
					doc /* Creates a #uses dependency (UML «use»). */
					attribute :>> label = "uses";
					attribute :>> description = "#uses dependency: the client needs the supplier (UML «use»)";
					attribute :>> representation = SymbolicRepresentationKind::path;
					perform action : OperationFromTemplate :>> operation {
						in ref = (UML3ElementTemplates::usesTemplate meta KerML::Package).ownedElement as SysML::Dependency;
					}
				}
				part realizesButton : Button :> abstractButtons {
					doc /* Creates a #realizes dependency (UML «realize»). */
					attribute :>> label = "realizes";
					attribute :>> description = "#realizes dependency: the client realizes the supplier's specification";
					attribute :>> representation = SymbolicRepresentationKind::path;
					perform action : OperationFromTemplate :>> operation {
						in ref = (UML3ElementTemplates::realizesTemplate meta KerML::Package).ownedElement as SysML::Dependency;
					}
				}
				part callsButton : Button :> abstractButtons {
					doc /* Creates a #calls dependency. */
					attribute :>> label = "calls";
					attribute :>> description = "#calls dependency: the client calls an operation of the supplier";
					attribute :>> representation = SymbolicRepresentationKind::path;
					perform action : OperationFromTemplate :>> operation {
						in ref = (UML3ElementTemplates::callsTemplate meta KerML::Package).ownedElement as SysML::Dependency;
					}
				}
				part createsButton : Button :> abstractButtons {
					doc /* Creates a #creates dependency. */
					attribute :>> label = "creates";
					attribute :>> description = "#creates dependency: the client creates instances of the supplier";
					attribute :>> representation = SymbolicRepresentationKind::path;
					perform action : OperationFromTemplate :>> operation {
						in ref = (UML3ElementTemplates::createsTemplate meta KerML::Package).ownedElement as SysML::Dependency;
					}
				}
				part tracesButton : Button :> abstractButtons {
					doc /* Creates a #traces dependency (UML «trace»). */
					attribute :>> label = "traces";
					attribute :>> description = "#traces dependency: the client traces to the supplier";
					attribute :>> representation = SymbolicRepresentationKind::path;
					perform action : OperationFromTemplate :>> operation {
						in ref = (UML3ElementTemplates::tracesTemplate meta KerML::Package).ownedElement as SysML::Dependency;
					}
				}
				part instantiatesButton : Button :> abstractButtons {
					doc /* Creates an #instantiates dependency. */
					attribute :>> label = "instantiates";
					attribute :>> description = "#instantiates dependency: the client instantiates the supplier template";
					attribute :>> representation = SymbolicRepresentationKind::path;
					perform action : OperationFromTemplate :>> operation {
						in ref = (UML3ElementTemplates::instantiatesTemplate meta KerML::Package).ownedElement as SysML::Dependency;
					}
				}
				part :>> focusedButton = usesButton;
			}
		}
		part :>> itemsPortsAttributesCategory { attribute :>> isCollapsed default true; }
		part :>> actionsCategory [0];
		part :>> otherActionsCategory [0];
		part :>> statesCategory [0];
		part :>> casesCategory [0];
		part :>> requirementsConstraintsCategory [0];
	}

	part def UML3ComponentPalette :> GeneralPalette {
		doc
		/*
		Palette of UML3 component diagrams: components, services, subsystems, the interfaces they realize,
		provided and required ports, and the connectors that wire them.

		Usage: 'part uml3ComponentPalette : UML3ComponentPalette :>> baseViewPalette;' in a view definition
		that specializes DS_Views::CoreViews::bsv.
		References: DS_Views::ViewPalettes::GeneralPalette; UML 2.5.1 Component diagram.
		*/
		@PaletteForDiagramKind { kind = UML3DiagramKinds::componentDiagram meta KerML::Type; }
		part uml3ComponentsCategory : ButtonsCategory :> buttonCategories {
			doc /* UML3 components and their ports. */
			attribute :>> isCollapsed default false;
			attribute :>> hasVisibleLabels default true;
			attribute :>> label default "UML3 Components";
			attribute :>> description default "UML3 components, services, subsystems, interfaces and ports";
			part componentButton : Button :> abstractButtons {
				doc /* Creates a UML3 Component: a #component part def. */
				attribute :>> label = "component";
				attribute :>> description = "#component part def: a UML3 Component";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::componentTemplate meta KerML::Package).ownedElement;
				}
			}
			part serviceButton : Button :> abstractButtons {
				doc /* Creates a UML3 Service: a #service part def. */
				attribute :>> label = "service";
				attribute :>> description = "#service part def: a deployable UML3 Service";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::serviceTemplate meta KerML::Package).ownedElement;
				}
			}
			part subsystemButton : Button :> abstractButtons {
				doc /* Creates a UML3 Subsystem: a #subsystem part def. */
				attribute :>> label = "subsystem";
				attribute :>> description = "#subsystem part def: a UML3 Subsystem of components";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::subsystemTemplate meta KerML::Package).ownedElement;
				}
			}
			part interfaceTypeButton : Button :> abstractButtons {
				doc /* Creates the UML3 InterfaceType a component provides or requires. */
				attribute :>> label = "interface";
				attribute :>> description = "#interfaceType item def: the contract of a port";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::interfaceTypeTemplate meta KerML::Package).ownedElement;
				}
			}
			part servicePortDefButton : Button :> abstractButtons {
				doc /* Creates a UML3 ServicePort definition: a #servicePort port def that types provided and required ports. */
				attribute :>> label = "service port def";
				attribute :>> description = "#servicePort port def: the port definition of a service contract";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::servicePortTemplate meta KerML::Package).ownedElement;
				}
			}
			part providedPortButton : Button :> abstractButtons {
				doc /* Creates a #provided port (the UML lollipop): the component offers the contract. */
				attribute :>> label = "provided port";
				attribute :>> description = "#provided port: offers a contract (must not be conjugated)";
				attribute :>> representation = SymbolicRepresentationKind::shapeOnBorder;
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::providedPortTemplate meta KerML::Package).ownedElement;
				}
			}
			part requiredPortButton : Button :> abstractButtons {
				doc /* Creates a #required port (the UML socket): the component needs the contract. */
				attribute :>> label = "required port";
				attribute :>> description = "#required port: needs a contract (type it with the conjugate ~)";
				attribute :>> representation = SymbolicRepresentationKind::shapeOnBorder;
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::requiredPortTemplate meta KerML::Package).ownedElement;
				}
			}
		}
		part uml3WiringCategory : ButtonsCategory :> buttonCategories {
			doc /* The connectors that wire UML3 components. */
			attribute :>> isCollapsed default false;
			attribute :>> hasVisibleLabels default true;
			attribute :>> label default "UML3 Wiring";
			attribute :>> description default "UML3 assembly and delegation connectors and realization";
			part assemblyButton : Button :> abstractButtons {
				doc /* Creates an #assembly connector between a required and a provided port. */
				attribute :>> label = "assembly";
				attribute :>> description = "#assembly connection: wires a required port to a provided port";
				attribute :>> representation = SymbolicRepresentationKind::path;
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::assemblyTemplate meta KerML::Package).ownedElement as SysML::ConnectionUsage;
				}
			}
			part delegationButton : Button :> abstractButtons {
				doc /* Creates a #delegation connector from a boundary port to an inner port. */
				attribute :>> label = "delegation";
				attribute :>> description = "#delegation connection: forwards a boundary port to an inner port";
				attribute :>> representation = SymbolicRepresentationKind::path;
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::delegationTemplate meta KerML::Package).ownedElement as SysML::ConnectionUsage;
				}
			}
			part realizesButton : Button :> abstractButtons {
				doc /* Creates a #realizes dependency from a component to the interface it realizes. */
				attribute :>> label = "realizes";
				attribute :>> description = "#realizes dependency: the component realizes the interface";
				attribute :>> representation = SymbolicRepresentationKind::path;
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::realizesTemplate meta KerML::Package).ownedElement as SysML::Dependency;
				}
			}
		}
		part :>> actionsCategory [0];
		part :>> otherActionsCategory [0];
		part :>> statesCategory [0];
		part :>> casesCategory [0];
		part :>> requirementsConstraintsCategory [0];
	}

	part def UML3DeploymentPalette :> GeneralPalette {
		doc
		/*
		Palette of UML3 deployment diagrams: nodes, devices, execution environments, artifacts, the
		communication paths between nodes and the deploy and manifest allocations.

		Usage: 'part uml3DeploymentPalette : UML3DeploymentPalette :>> baseViewPalette;' in a view definition
		that specializes DS_Views::CoreViews::bsv.
		References: DS_Views::ViewPalettes::GeneralPalette; UML 2.5.1 Deployment diagram.
		*/
		@PaletteForDiagramKind { kind = UML3DiagramKinds::deploymentDiagram meta KerML::Type; }
		part uml3DeploymentCategory : ButtonsCategory :> buttonCategories {
			doc /* UML3 deployment targets and artifacts. */
			attribute :>> isCollapsed default false;
			attribute :>> hasVisibleLabels default true;
			attribute :>> label default "UML3 Deployment";
			attribute :>> description default "UML3 nodes, devices, execution environments and artifacts";
			part nodeButton : Button :> abstractButtons {
				doc /* Creates a UML3 Node: a #node part def. */
				attribute :>> label = "node";
				attribute :>> description = "#node part def: a UML3 deployment Node";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::nodeTemplate meta KerML::Package).ownedElement;
				}
			}
			part deviceButton : Button :> abstractButtons {
				doc /* Creates a UML3 Device: a #device part def. */
				attribute :>> label = "device";
				attribute :>> description = "#device part def: a physical UML3 Device";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::deviceTemplate meta KerML::Package).ownedElement;
				}
			}
			part executionEnvironmentButton : Button :> abstractButtons {
				doc /* Creates a UML3 ExecutionEnvironment: an #executionEnvironment part def. */
				attribute :>> label = "execution environment";
				attribute :>> description = "#executionEnvironment part def: a container or runtime";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::executionEnvironmentTemplate meta KerML::Package).ownedElement;
				}
			}
			part artifactButton : Button :> abstractButtons {
				doc /* Creates a UML3 Artifact: an #artifact item def, a deployable file or image. */
				attribute :>> label = "artifact";
				attribute :>> description = "#artifact item def: a deployable UML3 Artifact";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::artifactTemplate meta KerML::Package).ownedElement;
				}
			}
		}
		part uml3DeploymentLinksCategory : ButtonsCategory :> buttonCategories {
			doc /* The links of a UML3 deployment diagram. */
			attribute :>> isCollapsed default false;
			attribute :>> hasVisibleLabels default true;
			attribute :>> label default "UML3 Deployment Links";
			attribute :>> description default "UML3 communication paths, deployments and manifestations";
			part communicationPathButton : Button :> abstractButtons {
				doc /* Creates a #communicationPath between two nodes. */
				attribute :>> label = "communication path";
				attribute :>> description = "#communicationPath connection def: a link between nodes";
				attribute :>> representation = SymbolicRepresentationKind::path;
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::communicationPathTemplate meta KerML::Package).ownedElement;
				}
			}
			part deployButton : Button :> abstractButtons {
				doc /* Creates a #deploy allocation from an artifact to its target. */
				attribute :>> label = "deploy";
				attribute :>> description = "#deploy allocation: deploys an artifact onto a node";
				attribute :>> representation = SymbolicRepresentationKind::path;
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::deployTemplate meta KerML::Package).ownedElement as SysML::AllocationUsage;
				}
			}
			part manifestButton : Button :> abstractButtons {
				doc /* Creates a #manifest allocation from an artifact to what it contains. */
				attribute :>> label = "manifest";
				attribute :>> description = "#manifest allocation: the artifact manifests a component";
				attribute :>> representation = SymbolicRepresentationKind::path;
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::manifestTemplate meta KerML::Package).ownedElement as SysML::AllocationUsage;
				}
			}
		}
		part :>> actionsCategory [0];
		part :>> otherActionsCategory [0];
		part :>> statesCategory [0];
		part :>> casesCategory [0];
		part :>> requirementsConstraintsCategory [0];
	}

	part def UML3DataPalette :> GeneralPalette {
		doc
		/*
		Palette of UML3 data models: entities, aggregate roots, value objects and relationships of the
		logical model, tables, database views, databases, columns and keys of the physical model, and the
		#mapsTo dependency that links the two.

		Usage: 'part uml3DataPalette : UML3DataPalette :>> baseViewPalette;' in a view definition that
		specializes DS_Views::CoreViews::bsv.
		References: DS_Views::ViewPalettes::GeneralPalette; UML3Data.
		*/
		@PaletteForDiagramKind { kind = UML3DiagramKinds::entityRelationshipDiagram meta KerML::Type; }
		part uml3LogicalDataCategory : ButtonsCategory :> buttonCategories {
			doc /* The logical data model: entities and their relationships. */
			attribute :>> isCollapsed default false;
			attribute :>> hasVisibleLabels default true;
			attribute :>> label default "UML3 Logical Data";
			attribute :>> description default "UML3 entities, aggregate roots, value objects and relationships";
			part entityButton : Button :> abstractButtons {
				doc /* Creates a UML3 Entity: an #entity item def with its own identity. */
				attribute :>> label = "entity";
				attribute :>> description = "#entity item def: a UML3 Entity (needs #primaryKey or #id)";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::entityTemplate meta KerML::Package).ownedElement;
				}
			}
			part aggregateRootButton : Button :> abstractButtons {
				doc /* Creates an #aggregateRoot item def, the entry point of a domain-driven design aggregate. */
				attribute :>> label = "aggregate root";
				attribute :>> description = "#aggregateRoot item def: the root of an aggregate";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::aggregateRootTemplate meta KerML::Package).ownedElement;
				}
			}
			part valueObjectButton : Button :> abstractButtons {
				doc /* Creates a #valueObject attribute def, a value compared by its content. */
				attribute :>> label = "value object";
				attribute :>> description = "#valueObject attribute def: a value without identity";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::valueObjectTemplate meta KerML::Package).ownedElement;
				}
			}
			part relationshipButton : Button :> abstractButtons {
				doc /* Creates a #relationship connection def whose end multiplicities give the cardinality. */
				attribute :>> label = "relationship";
				attribute :>> description = "#relationship connection def: an entity relationship";
				attribute :>> representation = SymbolicRepresentationKind::path;
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::relationshipTemplate meta KerML::Package).ownedElement;
				}
			}
		}
		part uml3PhysicalDataCategory : ButtonsCategory :> buttonCategories {
			doc /* The physical data model: tables, columns, keys and the mapping to the logical model. */
			attribute :>> isCollapsed default false;
			attribute :>> hasVisibleLabels default true;
			attribute :>> label default "UML3 Physical Data";
			attribute :>> description default "UML3 tables, database views, databases, columns, keys and mappings";
			part tableButton : Button :> abstractButtons {
				doc /* Creates a #table item def, which needs a #primaryKey column. */
				attribute :>> label = "table";
				attribute :>> description = "#table item def: a relational Table (needs a #primaryKey column)";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::tableTemplate meta KerML::Package).ownedElement;
				}
			}
			part databaseViewButton : Button :> abstractButtons {
				doc /* Creates a #dbView item def, which should set queryText. */
				attribute :>> label = "database view";
				attribute :>> description = "#dbView item def: a database view (set queryText)";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::databaseViewTemplate meta KerML::Package).ownedElement;
				}
			}
			part databaseButton : Button :> abstractButtons {
				doc /* Creates a #database part def that holds tables and views. */
				attribute :>> label = "database";
				attribute :>> description = "#database part def: a database holding tables and views";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::databaseTemplate meta KerML::Package).ownedElement;
				}
			}
			part columnButton : Button :> abstractButtons {
				doc /* Creates a #column attribute of a table. */
				attribute :>> label = "column";
				attribute :>> description = "#column attribute: a column of a table";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::columnTemplate meta KerML::Package).ownedElement;
				}
			}
			part primaryKeyButton : Button :> abstractButtons {
				doc /* Creates a #primaryKey attribute, the identifying column of a table or entity. */
				attribute :>> label = "primary key";
				attribute :>> description = "#primaryKey attribute: identifies rows of the table";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::primaryKeyTemplate meta KerML::Package).ownedElement;
				}
			}
			part foreignKeyButton : Button :> abstractButtons {
				doc /* Creates a #foreignKey reference to another entity or table. */
				attribute :>> label = "foreign key";
				attribute :>> description = "ref #foreignKey item: a reference to an entity or table";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::foreignKeyTemplate meta KerML::Package).ownedElement;
				}
			}
			part mapsToButton : Button :> abstractButtons {
				doc /* Creates a #mapsTo dependency from a table to the logical element it implements. */
				attribute :>> label = "maps to";
				attribute :>> description = "#mapsTo dependency: the table implements a logical element";
				attribute :>> representation = SymbolicRepresentationKind::path;
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::mapsToTemplate meta KerML::Package).ownedElement as SysML::Dependency;
				}
			}
		}
		part :>> actionsCategory [0];
		part :>> otherActionsCategory [0];
		part :>> statesCategory [0];
		part :>> casesCategory [0];
		part :>> requirementsConstraintsCategory [0];
	}

	part def UML3MessagingPalette :> GeneralPalette {
		doc
		/*
		Palette of UML3 message schemas: the message types (command, event, query, reply, document) and the
		channels, topics, queues and brokers that carry them.

		Usage: 'part uml3MessagingPalette : UML3MessagingPalette :>> baseViewPalette;' in a view definition
		that specializes DS_Views::CoreViews::bsv.
		References: DS_Views::ViewPalettes::GeneralPalette; UML3Messaging.
		*/
		@PaletteForDiagramKind { kind = UML3DiagramKinds::messageSchema meta KerML::Type; }
		part uml3MessagesCategory : ButtonsCategory :> buttonCategories {
			doc /* UML3 message types, each with the standard header. */
			attribute :>> isCollapsed default false;
			attribute :>> hasVisibleLabels default true;
			attribute :>> label default "UML3 Messages";
			attribute :>> description default "UML3 commands, events, queries, replies and documents";
			part commandButton : Button :> abstractButtons {
				doc /* Creates a #command item def: a request for one handler to act. */
				attribute :>> label = "command";
				attribute :>> description = "#command item def: a request addressed to one handler";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::commandTemplate meta KerML::Package).ownedElement;
				}
			}
			part domainEventButton : Button :> abstractButtons {
				doc /* Creates a #domainEvent item def: a fact that has happened. */
				attribute :>> label = "domain event";
				attribute :>> description = "#domainEvent item def: something that has happened";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::domainEventTemplate meta KerML::Package).ownedElement;
				}
			}
			part queryMessageButton : Button :> abstractButtons {
				doc /* Creates a #queryMessage item def: a request for data. */
				attribute :>> label = "query message";
				attribute :>> description = "#queryMessage item def: a request for data";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::queryMessageTemplate meta KerML::Package).ownedElement;
				}
			}
			part replyButton : Button :> abstractButtons {
				doc /* Creates a #reply item def: the answer to a command or query. */
				attribute :>> label = "reply";
				attribute :>> description = "#reply item def: the answer to a request";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::replyTemplate meta KerML::Package).ownedElement;
				}
			}
			part documentMessageButton : Button :> abstractButtons {
				doc /* Creates a #documentMessage item def: data passed without a request. */
				attribute :>> label = "document message";
				attribute :>> description = "#documentMessage item def: data passed between systems";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::documentMessageTemplate meta KerML::Package).ownedElement;
				}
			}
			part messageTypeButton : Button :> abstractButtons {
				doc /* Creates a #messageType item def when no more specific message keyword fits. */
				attribute :>> label = "message type";
				attribute :>> description = "#messageType item def: a message with the standard header";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::messageTypeTemplate meta KerML::Package).ownedElement;
				}
			}
		}
		part uml3ChannelsCategory : ButtonsCategory :> buttonCategories {
			doc /* The UML3 channels that carry messages. */
			attribute :>> isCollapsed default false;
			attribute :>> hasVisibleLabels default true;
			attribute :>> label default "UML3 Channels";
			attribute :>> description default "UML3 channels, topics, queues and brokers";
			part topicButton : Button :> abstractButtons {
				doc /* Creates a #topic part def: publish and subscribe to many consumers. */
				attribute :>> label = "topic";
				attribute :>> description = "#topic part def: publish-subscribe channel (declare @QualityOfService)";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::topicTemplate meta KerML::Package).ownedElement;
				}
			}
			part queueButton : Button :> abstractButtons {
				doc /* Creates a #queue part def: point-to-point delivery to one consumer. */
				attribute :>> label = "queue";
				attribute :>> description = "#queue part def: point-to-point channel (declare @QualityOfService)";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::queueTemplate meta KerML::Package).ownedElement;
				}
			}
			part channelButton : Button :> abstractButtons {
				doc /* Creates a #channel part def when the channel is neither a topic nor a queue. */
				attribute :>> label = "channel";
				attribute :>> description = "#channel part def: a channel that carries messages";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::channelTemplate meta KerML::Package).ownedElement;
				}
			}
			part brokerButton : Button :> abstractButtons {
				doc /* Creates a #broker part def: the middleware that owns channels. */
				attribute :>> label = "broker";
				attribute :>> description = "#broker part def: the middleware hosting the channels";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::brokerTemplate meta KerML::Package).ownedElement;
				}
			}
		}
		part uml3MessageFlowsCategory : ButtonsCategory :> buttonCategories {
			doc /* The UML3 flows that connect producers, channels and consumers. */
			attribute :>> isCollapsed default false;
			attribute :>> hasVisibleLabels default true;
			attribute :>> label default "UML3 Message Flows";
			attribute :>> description default "UML3 publishes, subscribes, sends and handles flows";
			part publishesButton : Button :> abstractButtons {
				doc /* Creates a #publishes flow from a producer's port to a channel. */
				attribute :>> label = "publishes";
				attribute :>> description = "#publishes flow: the producer publishes a message to a channel";
				attribute :>> representation = SymbolicRepresentationKind::path;
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::publishesTemplate meta KerML::Package).ownedElement as SysML::FlowUsage;
				}
			}
			part subscribesButton : Button :> abstractButtons {
				doc /* Creates a #subscribes flow from a channel to a consumer's port. */
				attribute :>> label = "subscribes";
				attribute :>> description = "#subscribes flow: the channel delivers a message to a consumer";
				attribute :>> representation = SymbolicRepresentationKind::path;
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::subscribesTemplate meta KerML::Package).ownedElement as SysML::FlowUsage;
				}
			}
			part sendsButton : Button :> abstractButtons {
				doc /* Creates a #sends flow from a sender to the receiver of a command or query. */
				attribute :>> label = "sends";
				attribute :>> description = "#sends flow: the sender addresses a message to one receiver";
				attribute :>> representation = SymbolicRepresentationKind::path;
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::sendsTemplate meta KerML::Package).ownedElement as SysML::FlowUsage;
				}
			}
			part handlesButton : Button :> abstractButtons {
				doc /* Creates a #handles flow from the handler back to the requester. */
				attribute :>> label = "handles";
				attribute :>> description = "#handles flow: the handler answers the requester";
				attribute :>> representation = SymbolicRepresentationKind::path;
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ElementTemplates::handlesTemplate meta KerML::Package).ownedElement as SysML::FlowUsage;
				}
			}
		}
		part :>> actionsCategory [0];
		part :>> otherActionsCategory [0];
		part :>> statesCategory [0];
		part :>> casesCategory [0];
		part :>> requirementsConstraintsCategory [0];
	}

	view def <UML3PackageDiagram> 'UML3 Package Diagram' :> bsv, UML3Views::PackageDiagram {
		doc
		/*
		UML3Views::PackageDiagram as a CATIA Magic symbolic view with the UML3 package palette.

		Usage: view storePackages : UML3CatiaMagic::'UML3 Package Diagram' { expose OnlineStore::**; }
		References: UML3Views::PackageDiagram; ViewDefinitionDesign; E17.
		*/
		render rendering compactRendering :>> asTreeDiagram, asInterconnectionDiagram {
			doc /* The rendering of this view: the compact tree form, which also replaces the nested rendering that Base Symbolic View inherits. */
		}
		part uml3PackagePalette : UML3PackagePalette :>> baseViewPalette {
			doc /* The palette of this view: the UML3 package palette in place of the Base Symbolic View palette. */
		}
	}

	view def <UML3ClassDiagram> 'UML3 Class Diagram' :> bsv, UML3Views::ClassDiagram {
		doc
		/*
		UML3Views::ClassDiagram as a CATIA Magic symbolic view with the UML3 class palette: the same filters
		and compact tree rendering, and palette buttons that create UML3 keyword elements.

		Usage: view domainClasses : UML3CatiaMagic::'UML3 Class Diagram' { expose OnlineStoreDomain::*; }
		For attributes, operations and documentation in compartments, use UML3Views::ClassDetailDiagram,
		which has no palette of its own (ViewDefinitionDesign).
		References: UML3Views::ClassDiagram; ViewDefinitionDesign; E17.
		*/
		render rendering compactRendering :>> asTreeDiagram, asInterconnectionDiagram {
			doc /* The rendering of this view: the compact tree form, which also replaces the nested rendering that Base Symbolic View inherits. */
		}
		part uml3ClassPalette : UML3ClassPalette :>> baseViewPalette {
			doc /* The palette of this view: the UML3 class palette in place of the Base Symbolic View palette. */
		}
	}

	view def <UML3ComponentDiagram> 'UML3 Component Diagram' :> bsv, UML3Views::ComponentDiagram {
		doc
		/*
		UML3Views::ComponentDiagram as a CATIA Magic symbolic view with the UML3 component palette: parts as
		nested nodes with their ports on the boundary, and buttons for components, ports and connectors.

		Usage: view architectureComponents : UML3CatiaMagic::'UML3 Component Diagram' { expose OnlineStoreArchitecture::*; }
		Both inherited renderings are named asInterconnectionDiagram, so the rendering below redefines them
		by qualified name (ViewDefinitionDesign).
		References: UML3Views::ComponentDiagram; E17.
		*/
		render rendering nestedRendering :>> DS_Views::CoreViews::'Symbolic View'::asInterconnectionDiagram,
			UML3Views::ComponentDiagram::asInterconnectionDiagram {
			doc /* The rendering of this view: the nested form, replacing both inherited renderings of that name. */
		}
		part uml3ComponentPalette : UML3ComponentPalette :>> baseViewPalette {
			doc /* The palette of this view: the UML3 component palette in place of the Base Symbolic View palette. */
		}
	}

	view def <UML3DeploymentDiagram> 'UML3 Deployment Diagram' :> bsv, UML3Views::DeploymentDiagram {
		doc
		/*
		UML3Views::DeploymentDiagram as a CATIA Magic symbolic view with the UML3 deployment palette.

		Usage: view deployment : UML3CatiaMagic::'UML3 Deployment Diagram' { expose OnlineStoreArchitecture::**; }
		References: UML3Views::DeploymentDiagram; ViewDefinitionDesign; E17.
		*/
		render rendering compactRendering :>> asTreeDiagram, asInterconnectionDiagram {
			doc /* The rendering of this view: the compact tree form, which also replaces the nested rendering that Base Symbolic View inherits. */
		}
		part uml3DeploymentPalette : UML3DeploymentPalette :>> baseViewPalette {
			doc /* The palette of this view: the UML3 deployment palette in place of the Base Symbolic View palette. */
		}
	}

	view def <UML3EntityRelationshipDiagram> 'UML3 Entity Relationship Diagram' :> bsv, UML3Views::EntityRelationshipDiagram {
		doc
		/*
		UML3Views::EntityRelationshipDiagram as a CATIA Magic symbolic view with the UML3 data palette, for
		both the logical and the physical data model.

		Usage: view logicalDataModel : UML3CatiaMagic::'UML3 Entity Relationship Diagram' { expose OnlineStoreDatabase::*; }
		References: UML3Views::EntityRelationshipDiagram; ViewDefinitionDesign; E17.
		*/
		render rendering compactRendering :>> asTreeDiagram, asInterconnectionDiagram {
			doc /* The rendering of this view: the compact tree form, which also replaces the nested rendering that Base Symbolic View inherits. */
		}
		part uml3DataPalette : UML3DataPalette :>> baseViewPalette {
			doc /* The palette of this view: the UML3 data palette in place of the Base Symbolic View palette. */
		}
	}

	view def <UML3MessageSchemaView> 'UML3 Message Schema View' :> bsv, UML3Views::MessageSchemaView {
		doc
		/*
		UML3Views::MessageSchemaView as a CATIA Magic symbolic view with the UML3 messaging palette.

		Usage: view messageSchemas : UML3CatiaMagic::'UML3 Message Schema View' { expose OnlineStoreMessaging::*; }
		References: UML3Views::MessageSchemaView; ViewDefinitionDesign; E17.
		*/
		render rendering compactRendering :>> asTreeDiagram, asInterconnectionDiagram {
			doc /* The rendering of this view: the compact tree form, which also replaces the nested rendering that Base Symbolic View inherits. */
		}
		part uml3MessagingPalette : UML3MessagingPalette :>> baseViewPalette {
			doc /* The palette of this view: the UML3 messaging palette in place of the Base Symbolic View palette. */
		}
	}

	package UML3ViewTemplates {
		doc
		/*
		The views that the UML3 Create View commands copy, one template package per command. Like the
		element templates, these packages own exactly one unnamed element and no documentation
		(TemplateDesign).

		Contents: one template package per UML3 view definition above.
		*/
		package packageDiagramTemplate { view : 'UML3 Package Diagram'; }
		package classDiagramTemplate { view : 'UML3 Class Diagram'; }
		package componentDiagramTemplate { view : 'UML3 Component Diagram'; }
		package deploymentDiagramTemplate { view : 'UML3 Deployment Diagram'; }
		package entityRelationshipDiagramTemplate { view : 'UML3 Entity Relationship Diagram'; }
		package messageSchemaViewTemplate { view : 'UML3 Message Schema View'; }
	}

	part def UML3ViewCreationDialog :> DS_UIComponents::UIComponents::SysMLViewCreationDialog {
		doc
		/*
		The Create View dialog with a UML3 Views category, in addition to the predefined symbolic and
		tabular view commands. Each command creates a view of one UML3 diagram kind, with its palette.

		Usage: activate it for a project with a ProjectViewCreationConfig package that redefines
		activeViewCreationDialog; customization/catia-magic/UML3CatiaMagicActivation.sysml does that.
		References: CATIA Magic SysML v2 Plugin 2026x R1 'Custom View Creation dialog'.
		*/
		part uml3ViewsMenu :> itemCategories {
			doc /* The UML3 view creation commands. */
			attribute :>> isCollapsed default false;
			attribute :>> label default "UML3 Views";
			part packageDiagramItem : DialogItem :> abstractItems {
				doc /* Creates a UML3 package diagram view. */
				attribute :>> label default "UML3 Package Diagram";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ViewTemplates::packageDiagramTemplate meta KerML::Package).ownedElement;
				}
			}
			part classDiagramItem : DialogItem :> abstractItems {
				doc /* Creates a UML3 class diagram view. */
				attribute :>> label default "UML3 Class Diagram";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ViewTemplates::classDiagramTemplate meta KerML::Package).ownedElement;
				}
			}
			part componentDiagramItem : DialogItem :> abstractItems {
				doc /* Creates a UML3 component diagram view. */
				attribute :>> label default "UML3 Component Diagram";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ViewTemplates::componentDiagramTemplate meta KerML::Package).ownedElement;
				}
			}
			part deploymentDiagramItem : DialogItem :> abstractItems {
				doc /* Creates a UML3 deployment diagram view. */
				attribute :>> label default "UML3 Deployment Diagram";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ViewTemplates::deploymentDiagramTemplate meta KerML::Package).ownedElement;
				}
			}
			part entityRelationshipDiagramItem : DialogItem :> abstractItems {
				doc /* Creates a UML3 entity relationship diagram view. */
				attribute :>> label default "UML3 Entity Relationship Diagram";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ViewTemplates::entityRelationshipDiagramTemplate meta KerML::Package).ownedElement;
				}
			}
			part messageSchemaViewItem : DialogItem :> abstractItems {
				doc /* Creates a UML3 message schema view. */
				attribute :>> label default "UML3 Message Schema View";
				perform action : OperationFromTemplate :>> operation {
					in ref = (UML3ViewTemplates::messageSchemaViewTemplate meta KerML::Package).ownedElement;
				}
			}
		}
	}
}
