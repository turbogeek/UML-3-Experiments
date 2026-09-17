library package UML3Core {
	doc
	/*
	UML3Core: the object-oriented modeling constructs of UML3, defined as a SysML v2 model library.

	It provides the UML classifiers and features that SysML v2 does not already have in the same form
	(Class, Interface, Operation, Association, Signal...). Each comes as an abstract library definition
	plus a semantic metadata keyword. Applying the keyword makes the annotated element implicitly
	specialize the library base: a keyworded definition subclassifies the base definition, a keyworded
	usage subsets the base collection usage.
	  #classType item def Customer { ... }     implies Customer :> UML3Core::Class
	  #operation action placeOrder { ... }     implies placeOrder :> UML3Core::operations

	Naming: keywords are lowerCamelCase. When the UML name is a reserved SysML or KerML word
	(interface, message, class, datatype...), the keyword gets a Type or verb suffix:
	#classType, #interfaceType, #uses.

	Rationale: keywords are semantic metadata rather than a new grammar, so UML3 models stay ordinary
	SysML v2 that any conforming tool can load, query and validate.

	Contents:
	- Classifiers: Class, ActiveClass, InterfaceType, DataType, Signal, ExceptionType
	  (#classType, #activeClass, #interfaceType, #dataType, #signal, #exceptionType).
	- Keyword category: DataTypeKind, the abstract parent of #dataType and of extension data type keywords.
	- Behavioral features: Operation, Query, Constructor (#operation, #query, #constructor).
	- Relationships: Association, Aggregation, Composition (#association, #aggregation, #composition).
	- Marker keywords: #static, #final, #id, #navigable, #singleton, #template, #templateParameter.
	- Generalization sets: @GeneralizationSet on the general, @InGeneralizationSet on each specific classifier.
	- AggregationKind: the UML aggregation kind as a value.
	- Dependency keywords: #uses, #realizes, #creates, #calls, #traces, #instantiates.
	References: KerML 7.4.13; KerML 9.2.16; SysML 7.27.3; docs/DESIGN.md.
	*/

	private import ScalarValues::*;
	private import Base::Anything;
	private import Metaobjects::SemanticMetadata;

	comment ClassifierDesign about Class, ActiveClass, InterfaceType, DataType, Signal, ExceptionType
		/*
		Classifiers. Classes, interfaces, signals and exceptions are item definitions: objects with identity
		that can be passed, stored and flowed. Data types are attribute definitions: values without identity.
		This follows the KerML split between Objects and DataValues, which are disjoint, so a class keyword
		on an attribute def, or a data type keyword on an item def, is a modeling error.
		References: KerML 7.3.2.5; KerML 9.2.5; SysML 7.7; SysML 7.10; E05.
		*/

	abstract item def Class {
		doc
		/*
		UML Class: a classifier whose instances are objects with identity, attributes and operations.

		Usage: apply #classType to an item def. Use 'part def' instead when the class is structural
		(it owns ports or composite parts); Part specializes Item, so it is still a Class.
		  #classType item def Customer { attribute name : String; }

		Rationale: an item def is the SysML v2 object that can be passed, stored and flowed, which matches
		the UML class used in software. Behaviors are not classes in UML3 (decision 2026-09-16).
		References: UML 2.5.1 Class; SysML 7.10; KerML 7.4.3; E05.
		*/
	}
	abstract item classes : Class[0..*] nonunique {
		doc
		/*
		All objects classified by a UML3 class. #classType usages subset this feature, so every classified
		usage in a model can be found from here.
		References: KerML 7.3.4.4.
		*/
	}

	abstract part def ActiveClass :> Class {
		doc
		/*
		UML active class: an object with its own thread of control and lifecycle, such as a service loop,
		an actor or a scheduler.

		Usage: #activeClass part def OrderProcessor { perform processOrders; }

		Rationale: a part def, because an active object is structural and usually performs or exhibits behavior.
		References: UML 2.5.1 Class (isActive); SysML 7.11.
		*/
	}
	abstract part activeClasses : ActiveClass[0..*] nonunique :> classes {
		doc /* All objects of active classes; #activeClass usages subset this feature. */
	}

	abstract item def InterfaceType {
		doc
		/*
		UML Interface: a contract of abstract operations and, optionally, abstract attributes.

		Usage: a class realizes an interface by specializing it and redefining its operations; realizing
		several interfaces is multiple specialization.
		  #interfaceType item def PaymentApi { abstract #operation action pay; }
		  #classType item def CardGateway :> PaymentApi { #operation action :>> pay; }

		Rationale: SysML v2 'interface def' is a connection between ports, not a UML contract, so the
		contract is an item def.
		References: UML 2.5.1 Interface; UML 2.5.1 InterfaceRealization; SysML 7.14.
		*/
	}
	abstract item interfaceTypes : InterfaceType[0..*] nonunique {
		doc /* All objects typed by a UML3 interface; #interfaceType usages subset this feature. */
	}

	abstract attribute def DataType {
		doc
		/*
		UML DataType: a value without identity; two values are equal when their contents are equal.

		Usage: #dataType attribute def Money { attribute amount : Decimal; attribute currency : String; }

		Rationale: SysML v2 attribute definitions already have value semantics (KerML DataValue).
		References: UML 2.5.1 DataType; SysML 7.7; KerML 7.4.2.
		*/
	}
	abstract attribute dataTypes : DataType[0..*] nonunique {
		doc /* All values of UML3 data types; #dataType usages subset this feature. */
	}

	abstract item def Signal :> Class {
		doc
		/*
		UML Signal: an asynchronous stimulus that one object sends and another accepts.

		Usage: #signal item def PaymentReceived { attribute orderId : String; }
		The signal is then sent and accepted with SysML 'send' and 'accept' actions or transitions.
		References: UML 2.5.1 Signal; SysML 7.16; SysML 7.17.
		*/
	}
	abstract item signals : Signal[0..*] nonunique :> classes {
		doc /* All signal instances; #signal usages subset this feature. */
	}

	abstract item def ExceptionType :> Signal {
		doc
		/*
		An exception or error object raised by an operation.

		Usage: #exceptionType item def OutOfStock { attribute sku : String; }
		An operation declares what it raises with a #raises dependency (UML3IDL) or in its documentation.

		Rationale: a signal, because an exception is an object that travels from raiser to handler.
		References: UML 2.5.1 Operation.raisedException; UML 2.5.1 Signal.
		*/
	}
	abstract item exceptionTypes : ExceptionType[0..*] nonunique :> signals {
		doc /* All exception instances; #exceptionType usages subset this feature. */
	}

	comment BehavioralFeatureDesign about Operation, Query, Constructor
		/*
		Behavioral features. A UML operation is a SysML action nested in the owning class, so it is a
		feature of that class and can be redefined by specializations. Parameters use SysML directions
		in, out and inout. The method that implements an operation is the action body, or a performed
		action def.
		References: UML 2.5.1 Operation; UML 2.5.1 Parameter; SysML 7.17.
		*/

	abstract action def Operation {
		doc
		/*
		UML Operation: a behavioral feature of a class or interface that can be invoked.

		Usage: declare it nested in the class or interface:
		  #operation action placeOrder { in cart : Cart; out order : Order; }
		A side-effect-free operation that returns a value should be a #query calc instead.
		References: UML 2.5.1 Operation; UML 2.5.1 Parameter; SysML 7.17.
		*/
	}
	abstract action operations : Operation[0..*] nonunique {
		doc /* All operations; #operation usages subset this feature. */
	}

	abstract calc def Query :> Operation {
		doc
		/*
		UML operation with isQuery = true: it returns a result and has no side effects.

		Usage: #query calc totalPrice { in order : Order; return : Decimal; }

		Rationale: a SysML calc is an action with a result, which is exactly a query.
		References: UML 2.5.1 Operation; SysML 7.19.
		*/
	}
	abstract calc queries : Query[0..*] nonunique :> operations {
		doc /* All query operations; #query usages subset this feature. */
	}

	abstract action def Constructor :> Operation {
		doc
		/*
		An operation that creates and initializes an instance of the owning class.

		Usage: #constructor action create { in name : String; out customer : Customer; }
		References: UML 2.5.1 Operation.
		*/
	}
	abstract action constructors : Constructor[0..*] nonunique :> operations {
		doc /* All constructors; #constructor usages subset this feature. */
	}

	comment RelationshipDesign about Association, Aggregation, Composition
		/*
		Relationships. Associations are SysML connection definitions with two 'end' features, whose
		multiplicities are the UML end multiplicities. Composite ownership is normally modeled by nesting
		(a 'part' or non-ref 'item' usage); the association forms exist for when the relationship must be a
		first-class, queryable element, for example in data models.
		References: UML 2.5.1 Association; UML 2.5.1 Property.aggregation; KerML 7.4.5; SysML 7.13.
		*/

	abstract connection def Association {
		doc
		/*
		UML Association: a semantic relationship between classifiers, with an end for each participant.

		Usage: declare two ends; attributes in the body make it an association class. Mark navigable ends
		with #navigable; a navigable end is usually mirrored as a 'ref' feature on the opposite participant.
		  #association connection def Places {
		    end [1] #navigable item customer : Customer;
		    end [0..*] item order : Order;
		  }
		References: UML 2.5.1 Association; UML 2.5.1 AssociationClass; KerML 7.4.5; SysML 7.13; E04.
		*/
	}
	abstract connection associations : Association[0..*] nonunique {
		doc /* All association links; #association usages subset this feature. */
	}

	abstract connection def Aggregation :> Association {
		doc
		/*
		Shared aggregation (hollow diamond): a whole-part association where the whole does not own the
		lifetime of its parts.

		Usage: #aggregation connection def TeamMembers { end [0..*] item team : Team; end [0..*] item member : Person; }
		References: UML 2.5.1 Property.aggregation.
		*/
	}
	abstract connection aggregations : Aggregation[0..*] nonunique :> associations {
		doc /* All shared-aggregation links; #aggregation usages subset this feature. */
	}

	abstract connection def Composition :> Association {
		doc
		/*
		Composite aggregation (filled diamond): the whole owns the lifetime of its parts.

		Usage: prefer a composite nested usage ('part' or non-ref 'item') where possible; use #composition
		when the relationship must be a first-class element.

		Rationale: SysML v2 expresses composition natively through ownership of non-reference usages.
		References: UML 2.5.1 Property.aggregation; SysML 7.6.
		*/
	}
	abstract connection compositions : Composition[0..*] nonunique :> associations {
		doc /* All composition links; #composition usages subset this feature. */
	}

	comment SemanticKeywordDesign about classType, activeClass, interfaceType, dataType,
		signal, exceptionType, operation, query, constructor,
		association, aggregation, composition
		/*
		Semantic keywords: the UML3 replacement for UML stereotypes. Each is a metadata definition that
		specializes SemanticMetadata and redefines baseType to a library usage. Applying it to an element
		adds an implied specialization to that library base, so the element gains real semantics (it is a
		Class, an Operation...) instead of carrying a label only.
		CATIA Magic applies only the first semantic keyword of an element (E02, E03); put the most important
		one first, and see check_rules.py R12.
		References: KerML 7.4.13; KerML 9.2.16; SysML 7.27.3; E01; E02; E03.
		*/

	metadata def <classType> cls :> SemanticMetadata {
		doc /* Keyword #classType: the element is a UML3 Class (a definition specializes Class, a usage subsets classes). */
		:>> baseType = classes meta SysML::Usage;
	}

	metadata def <activeClass> acls :> SemanticMetadata {
		doc /* Keyword #activeClass: the element is a UML3 ActiveClass; apply to part definitions and usages. */
		:>> baseType = activeClasses meta SysML::Usage;
	}

	metadata def <interfaceType> ifc :> SemanticMetadata {
		doc /* Keyword #interfaceType: the element is a UML3 InterfaceType (a contract of abstract operations). */
		:>> baseType = interfaceTypes meta SysML::Usage;
	}

	comment KeywordCategoryDesign about DataTypeKind, dataType
		/*
		Keyword categories. An extension keyword that refines a UML3 keyword, such as the IDL #union for
		#dataType, cannot specialize the UML3 keyword's metadata definition: that definition binds baseType,
		and KerML forbids a redefinition to override a bound (non-default) value
		(validateFeatureValueOverriding; CATIA Magic reports it as an error, E15). baseType cannot be a
		default value instead, because semantic metadata requires baseType to be bound.
		A category is an abstract metadata definition that specializes SemanticMetadata and leaves baseType
		unbound. The UML3 keyword and each refining extension keyword specialize the category and bind their
		own base, and views, rules and generators select the whole family with '@Category'.
		Rationale: views and rules in UML3 libraries select extension keywords without depending on the
		extension libraries (UML3-EXT-005), and check_rules.py R15 reports a keyword that overrides a bound base.
		References: KerML 8.3.4.10.2; KerML 8.4.4.13.3; KerML 7.4.13; E15.
		*/

	abstract metadata def DataTypeKind :> SemanticMetadata {
		doc
		/*
		Category of the data type keywords: #dataType and the extension keywords whose elements are data
		types with a more specific base, such as the IDL #union. It leaves baseType unbound, so it is not
		applied to elements itself.

		Usage: an extension keyword specializes the category and binds its own base, which must specialize
		UML3Core::dataTypes; a view selects all data type keywords with '@DataTypeKind'.
		  metadata def union :> DataTypeKind { :>> baseType = idlUnions meta SysML::Usage; }
		  view def ClassDiagram :> GeneralView { filter @classType or @DataTypeKind; }
		References: KerML 7.4.13; KerML 8.4.4.13.3; UML 2.5.1 DataType.
		*/
	}

	metadata def <dataType> dt :> DataTypeKind {
		doc /* Keyword #dataType: the element is a UML3 DataType; apply to attribute definitions and usages only. */
		:>> baseType = dataTypes meta SysML::Usage;
	}

	metadata def <signal> sig :> SemanticMetadata {
		doc /* Keyword #signal: the element is a UML3 Signal (an asynchronous stimulus). */
		:>> baseType = signals meta SysML::Usage;
	}

	metadata def <exceptionType> exc :> SemanticMetadata {
		doc /* Keyword #exceptionType: the element is a UML3 ExceptionType raised by operations. */
		:>> baseType = exceptionTypes meta SysML::Usage;
	}

	metadata def <operation> op :> SemanticMetadata {
		doc /* Keyword #operation: the action is a UML3 Operation of its owning class or interface. */
		:>> baseType = operations meta SysML::Usage;
	}

	metadata def <query> QueryMetadata :> SemanticMetadata {
		doc /* Keyword #query: the calc is a side-effect-free UML3 Query operation. */
		:>> baseType = queries meta SysML::Usage;
	}

	metadata def <constructor> ctor :> SemanticMetadata {
		doc /* Keyword #constructor: the action creates and initializes an instance of its owning class. */
		:>> baseType = constructors meta SysML::Usage;
	}

	metadata def <association> asc :> SemanticMetadata {
		doc /* Keyword #association: the connection is a UML3 Association. */
		:>> baseType = associations meta SysML::Usage;
	}

	metadata def <aggregation> agg :> SemanticMetadata {
		doc /* Keyword #aggregation: the connection is a shared aggregation (hollow diamond). */
		:>> baseType = aggregations meta SysML::Usage;
	}

	metadata def <composition> cps :> SemanticMetadata {
		doc /* Keyword #composition: the connection is a composite aggregation (filled diamond). */
		:>> baseType = compositions meta SysML::Usage;
	}

	comment MarkerKeywordDesign about staticFeatures, finalElements, identifierFeatures, singletonElements,
		templateElements, templateParameters, navigableEnds, static, final, id, navigable, singleton,
		template, templateParameter
		/*
		Marker keywords: UML properties with no SysML v2 equivalent.

		These are semantic keywords, so CATIA Magic shows them as labels («#static») and they can be
		queried as sets. Their baseType is a reference usage typed by Base::Anything, which belongs to no
		disjoint family, so a marker is valid on attributes, ref items, actions and definitions alike. On a
		definition the implied specialization is just Anything, which has no semantic effect; on a usage it
		subsets the marker set, e.g. staticFeatures.
		References: KerML 7.3.2.5; KerML 9.2.2; SysML 7.27.3; E01; E04.
		*/

	abstract ref staticFeatures : Anything[0..*] nonunique {
		doc /* All features marked #static. */
	}
	abstract ref finalElements : Anything[0..*] nonunique {
		doc /* All elements marked #final. */
	}
	abstract ref identifierFeatures : Anything[0..*] nonunique {
		doc /* All features marked #id. */
	}
	abstract ref singletonElements : Anything[0..*] nonunique {
		doc /* All elements marked #singleton. */
	}
	abstract ref templateElements : Anything[0..*] nonunique {
		doc /* All elements marked #template. */
	}
	abstract ref templateParameters : Anything[0..*] nonunique {
		doc /* All features marked #templateParameter. */
	}

	metadata def <static> stc :> SemanticMetadata {
		doc
		/*
		Keyword #static (UML isStatic): the feature belongs to the classifier, not to each instance.

		Usage: #static attribute instanceCount : Int32;
		References: UML 2.5.1 Property.isStatic.
		*/
		:>> baseType = staticFeatures meta SysML::Usage;
	}

	metadata def <final> Final :> SemanticMetadata {
		doc
		/*
		Keyword #final (UML isLeaf): the classifier may not be specialized, or the feature may not be redefined.

		Usage: #final #classType item def Money { ... }
		References: UML 2.5.1 RedefinableElement.isLeaf.
		*/
		:>> baseType = finalElements meta SysML::Usage;
	}

	metadata def <id> Identifier :> SemanticMetadata {
		doc
		/*
		Keyword #id (UML isID): the attribute takes part in the identity of instances of its owner.

		Usage: #id attribute customerId : Uuid;
		UML3Data uses the stronger #primaryKey for database keys.
		References: UML 2.5.1 Property.isID.
		*/
		:>> baseType = identifierFeatures meta SysML::Usage;
	}

	abstract ref navigableEnds : Anything[0..*] nonunique {
		doc /* All association ends marked #navigable. */
	}

	metadata def <navigable> nav :> SemanticMetadata {
		doc
		/*
		Keyword #navigable: the association end can be navigated from the opposite end.

		Usage, prefix form:  end [1] #navigable item customer : Customer;
		Usage, body form:    end [1] ref customer : Customer { @navigable; }
		Verified in CATIA Magic: ends join navigableEnds and show «#navigable», and connection usages that
		bind the ends remain valid.
		References: UML 2.5.1 Association; E04.
		*/
		:>> baseType = navigableEnds meta SysML::Usage;
	}

	metadata def <singleton> sgl :> SemanticMetadata {
		doc
		/*
		Keyword #singleton: the class has at most one instance at runtime.

		Usage: #singleton #classType item def Configuration { ... }
		Rationale: a design constraint that code generators and reviewers need, but UML expresses only
		through multiplicity conventions.
		*/
		:>> baseType = singletonElements meta SysML::Usage;
	}

	metadata def <template> tpl :> SemanticMetadata {
		doc
		/*
		Keyword #template: a templateable classifier, the UML3 form of a generic type.

		Usage: declare template parameters as abstract features marked #templateParameter; bind them by
		specializing the template and redefining each parameter with a concrete type.
		  #template item def Repository { abstract #templateParameter item entity; }
		  item def CustomerRepository :> Repository { item :>> entity : Customer; }
		References: UML 2.5.1 TemplateSignature; UML 2.5.1 TemplateBinding; KerML 7.3.4.5.
		*/
		:>> baseType = templateElements meta SysML::Usage;
	}

	metadata def <templateParameter> tplParam :> SemanticMetadata {
		doc
		/*
		Keyword #templateParameter: an abstract feature that stands for a template parameter; bind it with ':>>'.

		References: UML 2.5.1 TemplateParameter.
		*/
		:>> baseType = templateParameters meta SysML::Usage;
	}

	enum def AggregationKind {
		doc
		/*
		UML AggregationKind as a value, for tools and exchange formats that need the kind as data rather than
		as the Aggregation / Composition association keywords.
		References: UML 2.5.1 Property.aggregation.
		*/
		enum noAggregation {
			doc /* The end is not part of a whole-part relationship. */
		}
		enum sharedAggregation {
			doc /* Shared aggregation: the whole does not own the part's lifetime. */
		}
		enum compositeAggregation {
			doc /* Composite aggregation: the whole owns the part's lifetime. */
		}
	}

	metadata def GeneralizationSet {
		doc
		/*
		UML GeneralizationSet, applied to the general classifier: names a set of specializations and states
		whether they are covering (complete) and disjoint.

		Usage: on the general classifier
		  item def Payment { @GeneralizationSet { setName = "method"; isCovering = true; } }
		and on each specific classifier
		  item def CardPayment :> Payment { @InGeneralizationSet { setName = "method"; } }
		References: UML 2.5.1 GeneralizationSet; KerML 7.3.2.5.
		*/
		attribute setName : String {
			doc /* The name of the generalization set, matched by InGeneralizationSet on the specific classifiers. */
		}
		attribute isCovering : Boolean default false {
			doc /* True when every instance of the general classifier is an instance of some specific classifier. */
		}
		attribute isDisjoint : Boolean default true {
			doc /* True when no instance belongs to more than one specific classifier of the set. */
		}
	}

	metadata def InGeneralizationSet {
		doc
		/*
		Applied to a specific classifier to place its generalization in a named GeneralizationSet.
		References: UML 2.5.1 GeneralizationSet.
		*/
		attribute setName : String {
			doc /* The name of the GeneralizationSet declared on the general classifier. */
		}
	}

	comment DependencyKeywordDesign about DependencyKind, uses, realizes, creates,
		calls, traces, instantiates
		/*
		Dependency keywords. SysML v2 dependencies are relationships, not types, so they cannot be given
		semantics by specialization. These keywords are plain metadata restricted to dependencies; they
		classify the dependency for queries, diagrams and rules.
		References: UML 2.5.1 Dependency; UML 2.5.1 Usage; UML 2.5.1 Abstraction; SysML 7.3; SysML 7.27.
		*/

	abstract metadata def DependencyKind {
		doc
		/*
		Base of the dependency keywords: restricts them to SysML dependencies.

		Usage: #uses dependency from OrderService to PaymentGateway;
		*/
		:>> annotatedElement : SysML::Dependency;
	}

	metadata def <uses> UsesDependency :> DependencyKind {
		doc
		/*
		Keyword #uses (UML «use»): the client requires the supplier for its full implementation or operation.
		References: UML 2.5.1 Usage.
		*/
	}

	metadata def <realizes> rlz :> DependencyKind {
		doc
		/*
		Keyword #realizes: the client realizes the supplier's specification where specialization is not
		appropriate, for example a component realizing a specification owned by another team.
		References: UML 2.5.1 Realization.
		*/
	}

	metadata def <creates> crt :> DependencyKind {
		doc
		/*
		Keyword #creates (UML «create»): the client creates instances of the supplier.
		References: UML 2.5.1 Usage.
		*/
	}

	metadata def <calls> CallsDependency :> DependencyKind {
		doc
		/*
		Keyword #calls (UML «call»): an operation of the client calls an operation of the supplier.
		References: UML 2.5.1 Usage.
		*/
	}

	metadata def <traces> trc :> DependencyKind {
		doc
		/*
		Keyword #traces (UML «trace»): a historical or refinement link between elements that describe the
		same concept at different levels of abstraction.
		References: UML 2.5.1 Abstraction.
		*/
	}

	metadata def <instantiates> inst :> DependencyKind {
		doc
		/*
		Keyword #instantiates (UML «instantiate»): operations of the client create instances of the supplier.
		References: UML 2.5.1 Usage.
		*/
	}
}
