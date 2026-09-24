package OnlineStoreSysUMLSampleViews {
	doc
	/*
	The diagrams of the online store sample: SysML v2 views of OnlineStoreSysUMLSample, so that the sample can be
	seen as well as read.

	A sample that only exists as text is checked by the validator but never looked at. These views let CATIA Magic
	draw the sample and the test harness export it, which is the evidence that the semantic keywords produced the
	intended model: a box drawn as a class was selected by ClassDiagram's '@classType' filter, so '#classType item
	def Customer' really did become a UML3 class. What the diagrams show is checked against
	tests/cameo/sample-svg-expectations.json (E13, E14, E23).

	The views reuse the UML3 diagram kinds unchanged; nothing here is specific to the sample except what it
	exposes. OnlineStore.uml3 declares no views: a UML3 model says what it is, and the diagrams over it are a
	separate concern, as they are in SysML v2.

	Contents:
	- sampleClassDiagram (ClassDiagram): one box per class, interface, value type, enumeration, exception,
	  association and composition of the sample.
	- sampleClassDetails (ClassDetailDiagram): the same elements with their compartments, which is where the
	  attributes, the identity, the operations and the multiplicities become visible.
	- sampleClassTable (ClassTable): the classifiers of the sample as a table.
	References: UML 2.5.1 Class diagram; UML3Views::ClassDiagram; UML3Views::ClassDetailDiagram;
	UML3Views::ClassTable; SysML 7.26.2; SysML 9.2.20; E13; E14.
	*/
	private import UML3Views::*;

	view sampleClassDiagram : ClassDiagram {
		doc
		/*
		UML class diagram of the sample: Customer, PreferredCustomer, Order, OrderLine, CardPayment, the
		interface PaymentService, the value type Money, the enumeration OrderStatus, the exception
		OrderAlreadyShipped, and the relationships Places and Contains.

		It exposes the package's direct members; ClassDiagram keeps the elements that carry a class diagram
		keyword and the enum defs, so the attributes and the operations stay inside their classes. The two
		dependencies of the sample are exposed but unnamed, and CATIA Magic draws dependencies as edges
		rather than shapes (E13).
		Rationale: the one diagram a reader of samples/uml3 needs, and the one that shows the UML3 keywords
		were understood as UML concepts.
		References: UML 2.5.1 Class diagram; UML3Views::ClassDiagram; SysML 7.26.2.
		*/
		expose OnlineStoreSysUMLSample::*;
	}

	view sampleClassDetails : ClassDetailDiagram {
		doc
		/*
		The same elements as sampleClassDiagram, each drawn with its compartments: the documentation, the
		attributes with their types and multiplicities, and the operations with their parameters.

		This is the form that proves the detail of the model: that customerId is identifying, that email is
		unique, that isPaid is a query, that cancel takes a reason and returns a flag, and that an order owns
		one or more lines. ClassDetailDiagram declares no rendering, so tools draw full compartments and the
		diagram is much larger than the compact one (E14).
		Rationale: the compact diagram shows that the elements exist; this one shows that their features are
		right.
		References: UML 2.5.1 Class diagram; UML3Views::ClassDetailDiagram; SysML 7.26.5; E14.
		*/
		expose OnlineStoreSysUMLSample::*;
	}

	view sampleClassTable : ClassTable {
		doc
		/*
		The classifiers of the sample as a table: the classes, the interface, the value type and the
		enumeration, one per row.

		ClassTable selects fewer elements than ClassDiagram on purpose: the exception, the association and the
		composition have their own keywords and are not classifiers, so they do not appear. That difference is
		itself worth showing, and the expectations record it.
		Rationale: a table is how a reader compares many classifiers at once, and it exercises a view whose
		rendering is a table rather than a diagram.
		References: UML3Views::ClassTable; SysML 9.2.19; SysML 9.2.20.
		*/
		expose OnlineStoreSysUMLSample::*;
	}
}
