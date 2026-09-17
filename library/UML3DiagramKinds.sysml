library package UML3DiagramKinds {
	doc
	/*
	UML3DiagramKinds: which UML3 keywords belong to which diagram kind, as a model instead of a list repeated
	in every tool.

	One part per diagram kind records three things: the keywords whose elements a view of that kind shows,
	the keywords a modeling tool should let the user create on it, and the UML3Views definitions that render
	it. Keywords and view definitions are held as metaobjects ('classType meta KerML::Type'), not as
	strings, so a rename cannot leave a stale entry behind.

	Usage: a tool customization, report or generator reads the keywords of a kind instead of repeating them:
	the CATIA Magic class palette offers one button per keyword of classDiagram::creates, and
	UML3Views::ClassDiagram filters on the keywords of classDiagram::shows.
	tools/check_diagram_kinds.py compares this model with the filters in UML3Views and with the palettes in
	customization/catia-magic, so the three cannot drift apart.

	Rationale: the view filters and the CATIA Magic palettes held the same keyword lists twice, in different
	order and with different granularity, and nothing checked them against each other (issue I-35). 'shows'
	and 'creates' are separate lists because they answer different questions: a view shows an element as a
	shape, while a palette also creates features that appear inside a shape (#operation, #query) and cannot
	create markers that only annotate an existing element (#template).

	Contents:
	- DiagramKind: the definition, with shows, creates and views.
	- packageDiagram, classDiagram, classTable, componentDiagram, deploymentDiagram,
	  entityRelationshipDiagram, messageSchema, sequenceDiagram: the UML3 diagram kinds.
	References: UML3Views; docs/CATIA-MAGIC-CUSTOMIZATION.md; docs/DESIGN.md issue I-35.
	*/

	private import ScalarValues::*;
	private import UML3Core::*;
	private import UML3Components::*;
	private import UML3Data::*;
	private import UML3Messaging::*;

	part def DiagramKind {
		doc
		/*
		One UML3 diagram kind: what it shows, what can be created on it, and the views that render it.

		Usage: declare one part per diagram kind and bind the three lists.
		  part classDiagram : DiagramKind {
		    attribute :>> label = "class diagram";
		    attribute :>> shows = (classType meta KerML::Type);
		    attribute :>> creates = (classType meta KerML::Type);
		    attribute :>> views = (UML3Views::ClassDiagram meta KerML::Type);
		  }
		References: UML3Views; docs/DESIGN.md issue I-35.
		*/
		attribute label : String {
			doc /* The name a tool shows for this diagram kind, for example "class diagram". */
		}
		attribute shows : KerML::Type[0..*] nonunique {
			doc
			/*
			The keywords, and metaclasses where UML3 has no keyword, whose elements appear as shapes on this
			diagram kind. Every view definition of this kind selects exactly these with its filter.
			*/
		}
		attribute creates : KerML::Type[0..*] nonunique {
			doc
			/*
				The keywords a tool should offer for creating elements on this diagram kind, including features
			that appear inside a shape. A palette button exists for each of these; elements without a UML3
			keyword (packages, enumeration definitions, plain attributes, specializations) are created with
			the tool's own commands and are not listed. A kind that creates nothing, such as a table, binds
			no value: an empty sequence is not a valid expression.
			*/
		}
		attribute views : KerML::Type[0..*] nonunique {
			doc /* The UML3Views definitions that render this diagram kind: the compact form first, then the detail form. */
		}
	}

	part packageDiagram : DiagramKind {
		doc
		/*
		UML package diagram: the packages of a model and the dependencies between them. It has no keyword of
		its own, because every package is shown; #layer marks the architecture layers among them.
		References: UML 2.5.1 Package diagram; UML3Views::PackageDiagram.
		*/
		attribute :>> label = "package diagram";
		attribute :>> shows = (SysML::Package meta KerML::Type);
		attribute :>> creates = (
			layer meta KerML::Type,
			uses meta KerML::Type);
		attribute :>> views = (UML3Views::PackageDiagram meta KerML::Type);
	}

	part classDiagram : DiagramKind {
		doc
		/*
		UML class diagram: classifiers, their features and the relationships between them. #template is
		shown but not created, because it marks a definition that already exists; operations, queries and
		constructors are created but not shown as shapes, because they appear in a classifier's compartment.
		References: UML 2.5.1 Class diagram; UML3Views::ClassDiagram; UML3Views::ClassDetailDiagram.
		*/
		attribute :>> label = "class diagram";
		attribute :>> shows = (
			classType meta KerML::Type,
			activeClass meta KerML::Type,
			interfaceType meta KerML::Type,
			DataTypeKind meta KerML::Type,
			signal meta KerML::Type,
			exceptionType meta KerML::Type,
			template meta KerML::Type,
			SysML::EnumerationDefinition meta KerML::Type,
			association meta KerML::Type,
			aggregation meta KerML::Type,
			composition meta KerML::Type,
			DependencyKind meta KerML::Type);
		attribute :>> creates = (
			classType meta KerML::Type,
			activeClass meta KerML::Type,
			interfaceType meta KerML::Type,
			dataType meta KerML::Type,
			signal meta KerML::Type,
			exceptionType meta KerML::Type,
			operation meta KerML::Type,
			query meta KerML::Type,
			constructor meta KerML::Type,
			association meta KerML::Type,
			aggregation meta KerML::Type,
			composition meta KerML::Type,
			uses meta KerML::Type,
			realizes meta KerML::Type,
			calls meta KerML::Type,
			creates meta KerML::Type,
			traces meta KerML::Type,
			instantiates meta KerML::Type);
		attribute :>> views = (
			UML3Views::ClassDiagram meta KerML::Type,
			UML3Views::ClassDetailDiagram meta KerML::Type);
	}

	part classTable : DiagramKind {
		doc
		/*
		Tabular listing of the classifiers of a class diagram: classes, interfaces, data types and
		enumerations, one row each. A table has no palette, so nothing is created on it.
		References: UML3Views::ClassTable.
		*/
		attribute :>> label = "class table";
		attribute :>> shows = (
			classType meta KerML::Type,
			interfaceType meta KerML::Type,
			DataTypeKind meta KerML::Type,
			SysML::EnumerationDefinition meta KerML::Type);
		attribute :>> views = (UML3Views::ClassTable meta KerML::Type);
	}

	part componentDiagram : DiagramKind {
		doc
		/*
		UML component diagram: components, services and subsystems with their ports, the interfaces they
		provide and require, and the connectors and dependencies between them. Ports are shown by metaclass
		(every port def and port usage), so #provided, #required and #servicePort are created but not listed
		as shapes.
		References: UML 2.5.1 Component diagram; UML3Views::ComponentDiagram.
		*/
		attribute :>> label = "component diagram";
		attribute :>> shows = (
			component meta KerML::Type,
			service meta KerML::Type,
			subsystem meta KerML::Type,
			interfaceType meta KerML::Type,
			SysML::PortDefinition meta KerML::Type,
			SysML::PortUsage meta KerML::Type,
			assembly meta KerML::Type,
			delegation meta KerML::Type,
			SysML::ConnectionUsage meta KerML::Type,
			DependencyKind meta KerML::Type);
		attribute :>> creates = (
			component meta KerML::Type,
			service meta KerML::Type,
			subsystem meta KerML::Type,
			interfaceType meta KerML::Type,
			servicePort meta KerML::Type,
			provided meta KerML::Type,
			required meta KerML::Type,
			assembly meta KerML::Type,
			delegation meta KerML::Type,
			realizes meta KerML::Type);
		attribute :>> views = (UML3Views::ComponentDiagram meta KerML::Type);
	}

	part deploymentDiagram : DiagramKind {
		doc
		/*
		UML deployment diagram: the nodes, devices and execution environments a system runs on, the
		artifacts deployed to them, and the communication paths between them.
		References: UML 2.5.1 Deployment diagram; UML3Views::DeploymentDiagram; UML3Views::DeploymentDetailDiagram.
		*/
		attribute :>> label = "deployment diagram";
		attribute :>> shows = (
			artifact meta KerML::Type,
			node meta KerML::Type,
			device meta KerML::Type,
			executionEnvironment meta KerML::Type,
			communicationPath meta KerML::Type,
			deploy meta KerML::Type,
			manifest meta KerML::Type);
		attribute :>> creates = (
			node meta KerML::Type,
			device meta KerML::Type,
			executionEnvironment meta KerML::Type,
			artifact meta KerML::Type,
			communicationPath meta KerML::Type,
			deploy meta KerML::Type,
			manifest meta KerML::Type);
		attribute :>> views = (
			UML3Views::DeploymentDiagram meta KerML::Type,
			UML3Views::DeploymentDetailDiagram meta KerML::Type);
	}

	part entityRelationshipDiagram : DiagramKind {
		doc
		/*
		Data model: the entities, aggregate roots, value objects and relationships of the logical level, the
		tables, database views and databases of the physical level, and the #mapsTo dependencies between
		them. Columns and keys are created but not shown as shapes, because they are features of a table.
		References: UML3Data; UML3Views::EntityRelationshipDiagram; UML3Views::EntityRelationshipDetailDiagram.
		*/
		attribute :>> label = "entity relationship diagram";
		attribute :>> shows = (
			entity meta KerML::Type,
			aggregateRoot meta KerML::Type,
			valueObject meta KerML::Type,
			relationship meta KerML::Type,
			table meta KerML::Type,
			dbView meta KerML::Type,
			database meta KerML::Type,
			mapsTo meta KerML::Type);
		attribute :>> creates = (
			entity meta KerML::Type,
			aggregateRoot meta KerML::Type,
			valueObject meta KerML::Type,
			relationship meta KerML::Type,
			table meta KerML::Type,
			dbView meta KerML::Type,
			database meta KerML::Type,
			column meta KerML::Type,
			primaryKey meta KerML::Type,
			foreignKey meta KerML::Type,
			mapsTo meta KerML::Type);
		attribute :>> views = (
			UML3Views::EntityRelationshipDiagram meta KerML::Type,
			UML3Views::EntityRelationshipDetailDiagram meta KerML::Type);
	}

	part messageSchema : DiagramKind {
		doc
		/*
		Messaging model: the message types, the channels that carry them, the broker that hosts the
		channels, and the flows between producers, channels and consumers.
		References: UML3Messaging; UML3Views::MessageSchemaView; UML3Views::MessageSchemaDetailView.
		*/
		attribute :>> label = "message schema";
		attribute :>> shows = (
			messageType meta KerML::Type,
			command meta KerML::Type,
			domainEvent meta KerML::Type,
			queryMessage meta KerML::Type,
			reply meta KerML::Type,
			documentMessage meta KerML::Type,
			channel meta KerML::Type,
			topic meta KerML::Type,
			queue meta KerML::Type,
			broker meta KerML::Type,
			publishes meta KerML::Type,
			subscribes meta KerML::Type,
			sends meta KerML::Type,
			handles meta KerML::Type);
		attribute :>> creates = (
			command meta KerML::Type,
			domainEvent meta KerML::Type,
			queryMessage meta KerML::Type,
			reply meta KerML::Type,
			documentMessage meta KerML::Type,
			messageType meta KerML::Type,
			topic meta KerML::Type,
			queue meta KerML::Type,
			channel meta KerML::Type,
			broker meta KerML::Type,
			publishes meta KerML::Type,
			subscribes meta KerML::Type,
			sends meta KerML::Type,
			handles meta KerML::Type);
		attribute :>> views = (
			UML3Views::MessageSchemaView meta KerML::Type,
			UML3Views::MessageSchemaDetailView meta KerML::Type);
	}

	part sequenceDiagram : DiagramKind {
		doc
		/*
		UML sequence diagram: the interactions of the model, drawn by the sequence renderer. It filters
		nothing, because the renderer decides what a lifeline, an occurrence and a message are, and UML3
		adds no keyword of its own; nothing is created from a UML3 palette.
		References: UML 2.5.1 Sequence diagram; UML3Views::SequenceDiagram.
		*/
		attribute :>> label = "sequence diagram";
		attribute :>> views = (UML3Views::SequenceDiagram meta KerML::Type);
	}
}
