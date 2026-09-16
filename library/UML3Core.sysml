library package UML3Core {
	doc
	/*
	 * UML3Core - object-oriented modeling constructs for SysML v2.
	 *
	 * Provides UML-equivalent classifiers (Class, Interface, Operation, Association,
	 * Signal...) as a SysML v2 model library plus SemanticMetadata "keywords".
	 * Applying a keyword makes the annotated element implicitly specialize the library
	 * base (KerML 9.2.16): a keyworded definition SUBCLASSIFIES the base definition,
	 * a keyworded usage SUBSETS the base collection usage.
	 *
	 *   #classType item def Customer { ... }      implies Customer :> UML3Core::Class
	 *   #operation action placeOrder { ... }      implies placeOrder :> UML3Core::operations
	 *
	 * Naming rule: keywords are lowerCamelCase. When the UML name is a reserved SysML
	 * word (SysML: interface, message, use, event; KerML: class, datatype, feature...) the
	 * keyword gets a Type/verb suffix,
	 * e.g. #classType, #interfaceType, #uses.
	 */

	private import ScalarValues::*;
	private import Base::Anything;
	private import Metaobjects::SemanticMetadata;

	/* =====================================================================
	 * Classifiers
	 * ===================================================================== */

	abstract item def Class {
		doc
		/*
		 * UML Class. Modeled as an item def (an object with identity that can be
		 * passed, stored and flowed). Specialize with 'part def' when the class is
		 * structural (owns ports / composite parts) - Part :> Item keeps it a Class.
		 */
	}
	abstract item classes : Class[0..*] nonunique;

	abstract part def ActiveClass :> Class {
		doc /* UML active class: an object with its own thread of control / lifecycle. */
	}
	abstract part activeClasses : ActiveClass[0..*] nonunique :> classes;

	abstract item def InterfaceType {
		doc
		/*
		 * UML Interface: a contract of abstract operations and (optionally) abstract
		 * attributes. A Class realizes an interface by specializing it (':>') and
		 * redefining (':>>') its abstract operations. Multiple realization = multiple
		 * specialization.
		 */
	}
	abstract item interfaceTypes : InterfaceType[0..*] nonunique;

	abstract attribute def DataType {
		doc
		/*
		 * UML DataType: a value without identity (equality by value). Maps onto
		 * SysML attribute def semantics.
		 */
	}
	abstract attribute dataTypes : DataType[0..*] nonunique;

	abstract item def Signal :> Class {
		doc /* UML Signal: an asynchronous stimulus that can be sent and accepted. */
	}
	abstract item signals : Signal[0..*] nonunique :> classes;

	abstract item def ExceptionType :> Signal {
		doc /* An exception / error object raised by an operation. */
	}
	abstract item exceptionTypes : ExceptionType[0..*] nonunique :> signals;

	/* =====================================================================
	 * Behavioral features
	 * ===================================================================== */

	abstract action def Operation {
		doc
		/*
		 * UML Operation. Declare nested inside a Class/InterfaceType:
		 *   #operation action placeOrder { in cart : Cart; out order : Order; }
		 * Parameters use SysML directions (in / out / inout). A side-effect-free
		 * operation with a return value should be a #query calc instead.
		 */
	}
	abstract action operations : Operation[0..*] nonunique;

	abstract calc def Query :> Operation {
		doc /* UML operation with isQuery=true: returns a result, no side effects. */
	}
	abstract calc queries : Query[0..*] nonunique :> operations;

	abstract action def Constructor :> Operation {
		doc /* Creates and initializes an instance of the owning Class. */
	}
	abstract action constructors : Constructor[0..*] nonunique :> operations;

	/* =====================================================================
	 * Relationships
	 * ===================================================================== */

	abstract connection def Association {
		doc
		/*
		 * UML Association. Binary associations declare two 'end' features whose
		 * multiplicities are the UML end multiplicities. Attributes declared in
		 * the body make it an AssociationClass. Mark navigable ends with @Navigable
		 * (end body) or #navigable (prefix); navigable ends are usually mirrored as
		 * 'ref' features on the opposite participant.
		 */
	}
	abstract connection associations : Association[0..*] nonunique;

	abstract connection def Aggregation :> Association {
		doc /* Shared aggregation (hollow diamond): the whole does not own part lifetime. */
	}
	abstract connection aggregations : Aggregation[0..*] nonunique :> associations;

	abstract connection def Composition :> Association {
		doc
		/*
		 * Composite aggregation (filled diamond): the whole owns part lifetime.
		 * Prefer a composite nested usage ('part' / non-ref 'item') where possible;
		 * use #composition when the relationship must be a first-class element.
		 */
	}
	abstract connection compositions : Composition[0..*] nonunique :> associations;

	/* =====================================================================
	 * Semantic keywords (stereotypes that imply specialization)
	 * ===================================================================== */

	metadata def <classType> ClassMetadata :> SemanticMetadata {
		:>> baseType = classes meta SysML::Usage;
	}

	metadata def <activeClass> ActiveClassMetadata :> SemanticMetadata {
		:>> baseType = activeClasses meta SysML::Usage;
	}

	metadata def <interfaceType> InterfaceTypeMetadata :> SemanticMetadata {
		:>> baseType = interfaceTypes meta SysML::Usage;
	}

	metadata def <dataType> DataTypeMetadata :> SemanticMetadata {
		:>> baseType = dataTypes meta SysML::Usage;
	}

	metadata def <signal> SignalMetadata :> SemanticMetadata {
		:>> baseType = signals meta SysML::Usage;
	}

	metadata def <exceptionType> ExceptionTypeMetadata :> SemanticMetadata {
		:>> baseType = exceptionTypes meta SysML::Usage;
	}

	metadata def <operation> OperationMetadata :> SemanticMetadata {
		:>> baseType = operations meta SysML::Usage;
	}

	metadata def <query> QueryMetadata :> SemanticMetadata {
		:>> baseType = queries meta SysML::Usage;
	}

	metadata def <constructor> ConstructorMetadata :> SemanticMetadata {
		:>> baseType = constructors meta SysML::Usage;
	}

	metadata def <association> AssociationMetadata :> SemanticMetadata {
		:>> baseType = associations meta SysML::Usage;
	}

	metadata def <aggregation> AggregationMetadata :> SemanticMetadata {
		:>> baseType = aggregations meta SysML::Usage;
	}

	metadata def <composition> CompositionMetadata :> SemanticMetadata {
		:>> baseType = compositions meta SysML::Usage;
	}

	/* =====================================================================
	 * Marker keywords (UML properties with no SysML v2 equivalent)
	 *
	 * These are SEMANTIC keywords so CATIA Magic shows them as labels («#static»)
	 * and they can be queried as sets. Their baseType is a reference usage typed by
	 * Base::Anything, which belongs to no disjoint family, so a marker is valid on
	 * attributes, ref items, actions and definitions alike (experiment E01). On a
	 * definition the implied specialization is just Anything (no semantic effect);
	 * on a usage it subsets the marker set, e.g. staticFeatures.
	 * ===================================================================== */

	abstract ref staticFeatures : Anything[0..*] nonunique;
	abstract ref finalElements : Anything[0..*] nonunique;
	abstract ref identifierFeatures : Anything[0..*] nonunique;
	abstract ref singletonElements : Anything[0..*] nonunique;
	abstract ref templateElements : Anything[0..*] nonunique;
	abstract ref templateParameters : Anything[0..*] nonunique;

	metadata def <static> Static :> SemanticMetadata {
		doc /* UML isStatic: the feature belongs to the classifier, not to each instance. */
		:>> baseType = staticFeatures meta SysML::Usage;
	}

	metadata def <final> Final :> SemanticMetadata {
		doc /* UML isLeaf: the classifier may not be specialized / the operation not redefined. */
		:>> baseType = finalElements meta SysML::Usage;
	}

	metadata def <id> Identifier :> SemanticMetadata {
		doc /* UML isID: the attribute participates in the identity of instances of its owner. */
		:>> baseType = identifierFeatures meta SysML::Usage;
	}

	abstract ref navigableEnds : Anything[0..*] nonunique;

	metadata def <navigable> Navigable :> SemanticMetadata {
		doc
		/*
		 * Marks an association end as navigable from the opposite end.
		 *   body form:   end [1] ref customer : Customer { @Navigable; }
		 *   prefix form: end [1] #navigable item customer : Customer;
		 * Verified in CATIA Magic (experiment E04): ends join navigableEnds, show «#navigable»,
		 * and connection usages binding the ends remain valid.
		 */
		:>> baseType = navigableEnds meta SysML::Usage;
	}

	metadata def <singleton> Singleton :> SemanticMetadata {
		doc /* The class has at most one instance at runtime. */
		:>> baseType = singletonElements meta SysML::Usage;
	}

	metadata def <template> Template :> SemanticMetadata {
		doc
		/*
		 * UML templateable classifier. Template parameters are abstract features
		 * marked #templateParameter; binding is done by specializing the template
		 * and redefining (':>>') each parameter with a concrete type.
		 */
		:>> baseType = templateElements meta SysML::Usage;
	}

	metadata def <templateParameter> TemplateParameter :> SemanticMetadata {
		doc /* An abstract feature that stands for a template parameter; bind it with ':>>'. */
		:>> baseType = templateParameters meta SysML::Usage;
	}

	enum def AggregationKind {
		doc /* UML AggregationKind, for tools that need it as a value. */
		enum noAggregation;
		enum sharedAggregation;
		enum compositeAggregation;
	}

	metadata def GeneralizationSet {
		doc
		/*
		 * UML GeneralizationSet, applied to the GENERAL classifier. Specific classifiers
		 * declare membership with @InGeneralizationSet using the same setName.
		 */
		attribute setName : String;
		attribute isCovering : Boolean default false;
		attribute isDisjoint : Boolean default true;
	}

	metadata def InGeneralizationSet {
		doc /* Applied to a SPECIFIC classifier to place its generalization in a named set. */
		attribute setName : String;
	}

	/* =====================================================================
	 * Dependency keywords (dependencies are not Types, so these are plain metadata)
	 * ===================================================================== */

	abstract metadata def DependencyKind {
		:>> annotatedElement : SysML::Dependency;
	}

	metadata def <uses> UsesDependency :> DependencyKind {
		doc /* UML «use»: the client requires the supplier for its implementation. */
	}

	metadata def <realizes> RealizesDependency :> DependencyKind {
		doc /* UML Realization when specialization is not appropriate (e.g. component realizes spec). */
	}

	metadata def <creates> CreatesDependency :> DependencyKind {
		doc /* UML «create»: the client creates instances of the supplier. */
	}

	metadata def <calls> CallsDependency :> DependencyKind {
		doc /* UML «call»: an operation of the client calls an operation of the supplier. */
	}

	metadata def <traces> TracesDependency :> DependencyKind {
		doc /* UML «trace»: historical / refinement link between model elements. */
	}

	metadata def <instantiates> InstantiatesDependency :> DependencyKind {
		doc /* UML «instantiate»: operations of the client create instances of the supplier. */
	}
}
