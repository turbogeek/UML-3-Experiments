package DMMStructure {
	doc
	/*
	DMMStructure: the concepts of a structural (class) model: the kinds of classifier, the features that
	classifiers own, operations and their parameters, and the relationships between classifiers.

	Contents:
	- Classifier: the common concept of classes, data types, interfaces and signals.
	- Class, ActiveClass: classifiers whose instances are objects with identity.
	- DataType, ScalarType, FacetValue, FacetKind, Enumeration, EnumerationLiteral: classifiers whose instances
	  are values without identity, and the restrictions on their value spaces.
	- InterfaceType, Signal, ExceptionType: contracts and asynchronous stimuli.
	- TypedElement, Feature, StructuralFeature, Attribute: typed, counted features.
	- Operation, Parameter, ParameterDirectionKind: behavioral features.
	- Generalization, GeneralizationSet, InterfaceRealization: relationships between classifiers.
	- Association, AssociationEnd, AggregationKind, AssociationClass: links between instances.
	- Dependency, DependencyKind, Constraint: needs and invariants.
	References: UML 2.5.1 Class; UML 2.5.1 DataType; UML 2.5.1 Interface; UML 2.5.1 Property; UML 2.5.1 Operation;
	UML 2.5.1 Association; UML 2.5.1 GeneralizationSet; SysML 7.6.
	*/
	private import ScalarValues::*;
	private import UML3Core::*;
	private import DMMFoundation::*;

	abstract #classType item def Classifier :> Namespace {
		doc /* A concept whose instances share features: the common concept of classes, data types, interfaces and signals. */
		attribute isAbstract : Boolean {
			doc /* True when the classifier has no direct instances and exists to be specialized. */
		}
		attribute isFinal : Boolean {
			doc /* True when the classifier may not be specialized (UML isLeaf). */
		}
		item features : Feature[0..*] ordered :> ownedElements {
			doc /* The attributes and operations that the classifier owns. */
		}
	}

	#classType item def Class :> Classifier {
		doc /* A classifier whose instances are objects with identity, which have state (attributes) and behavior (operations). */
	}

	#classType item def ActiveClass :> Class {
		doc /* A class whose objects have their own thread of control and lifecycle, described by a classifier behavior. */
	}

	#classType item def DataType :> Classifier {
		doc /* A classifier whose instances are values without identity, equal when their attribute values are equal. */
	}

	#classType item def ScalarType :> DataType {
		doc
		/*
		A data type whose values have no parts, such as a sized integer, a floating-point number, a character or a
		text; facets restrict its value space.
		*/
		attribute facets : FacetValue[0..*] {
			doc /* The restrictions on the value space, such as bounds, lengths, digits or a pattern. */
		}
	}

	#dataType attribute def FacetValue {
		doc /* One restriction on the value space of a scalar type: a kind of facet and its value. */
		attribute kind : FacetKind {
			doc /* Which restriction the facet states. */
		}
		attribute value : String {
			doc /* The value of the restriction, written as in the facet's kind, such as 0 or [A-Z]{3}. */
		}
	}

	enum def FacetKind {
		doc /* The kinds of restriction on a value space, following the facets of XML Schema that software types need. */
		enum minInclusive {
			doc /* The smallest allowed value. */
		}
		enum maxInclusive {
			doc /* The largest allowed value. */
		}
		enum minLength {
			doc /* The least number of characters or octets. */
		}
		enum maxLength {
			doc /* The greatest number of characters or octets. */
		}
		enum pattern {
			doc /* A regular expression that every value matches. */
		}
		enum totalDigits {
			doc /* The greatest number of decimal digits (precision). */
		}
		enum fractionDigits {
			doc /* The greatest number of digits after the decimal point (scale). */
		}
	}

	#classType item def Enumeration :> DataType {
		doc /* A data type whose values are a fixed, ordered list of named literals. */
		item literals : EnumerationLiteral[0..*] ordered :> ownedElements {
			doc /* The literals of the enumeration, in order. */
		}
	}

	#classType item def EnumerationLiteral :> ModelElement {
		doc /* One named value of an enumeration, with an explicit code where a target format needs one. */
		attribute code : String[0..1] {
			doc /* The explicit value of the literal, such as an integer code or a string, when it has one. */
		}
	}

	#classType item def InterfaceType :> Classifier {
		doc /* A classifier that is a contract: abstract operations and attributes that realizing classifiers provide. */
	}

	#classType item def Signal :> Classifier {
		doc /* A classifier whose instances one object sends asynchronously to another. */
	}

	#classType item def ExceptionType :> Signal {
		doc /* A signal that an operation raises to report that it could not complete normally. */
	}

	abstract #classType item def TypedElement :> ModelElement {
		doc /* An element whose values are instances of a classifier, with a multiplicity that counts them. */
		ref item valueType : Classifier[0..1] {
			doc /* The classifier of the values. */
		}
		attribute lowerBound : Natural {
			doc /* The least number of values. */
		}
		attribute upperBound : Natural[0..1] {
			doc /* The greatest number of values; absent when the number is unbounded (*). */
		}
		attribute isOrdered : Boolean {
			doc /* True when the values are in a meaningful order. */
		}
		attribute isUnique : Boolean {
			doc /* True when no value occurs twice. */
		}
	}

	abstract #classType item def Feature :> ModelElement {
		doc /* A characteristic that a classifier owns: a structural feature or an operation. */
		attribute isStatic : Boolean {
			doc /* True when the feature belongs to the classifier itself instead of to each of its instances. */
		}
	}

	abstract #classType item def StructuralFeature :> Feature, TypedElement {
		doc /* A typed, counted feature whose values make up the state of an instance: an attribute or an association end. */
		attribute isReadOnly : Boolean {
			doc /* True when the values cannot change after the instance is initialized. */
		}
	}

	#classType item def Attribute :> StructuralFeature {
		doc /* A structural feature of a classifier, typed by a data type or a class. */
		attribute defaultValue : String[0..1] {
			doc /* The expression that gives the initial value, when there is one. */
		}
		attribute isDerived : Boolean {
			doc /* True when the value is computed from other values instead of stored. */
		}
		attribute isIdentifying : Boolean {
			doc /* True when the attribute takes part in the identity of the instances (UML isID). */
		}
	}

	#classType item def Operation :> Feature {
		doc
		/*
		A behavioral feature: a service that the instances of a classifier, or the classifier itself, provide, with
		parameters and possibly a result.
		*/
		item parameters : Parameter[0..*] ordered {
			doc /* The inputs, outputs and result of the operation, in order. */
		}
		attribute isAbstract : Boolean {
			doc /* True when the operation has no method here; specializations and realizations provide one. */
		}
		attribute isQuery : Boolean {
			doc /* True when calling the operation does not change the state of the system. */
		}
		attribute isConstructor : Boolean {
			doc /* True when the operation creates and initializes a new instance. */
		}
		ref item raisedExceptions : ExceptionType[0..*] {
			doc /* The exception types that the operation may raise. */
		}
	}

	#classType item def Parameter :> TypedElement {
		doc /* An input, output or result of an operation. */
		attribute direction : ParameterDirectionKind {
			doc /* Whether a value flows into the operation, out of it, both ways, or is its result. */
		}
		attribute defaultValue : String[0..1] {
			doc /* The expression that gives the value when a caller passes none. */
		}
	}

	enum def ParameterDirectionKind {
		doc /* The direction in which a parameter's values flow. */
		enum 'in' {
			doc /* From the caller into the operation. */
		}
		enum 'out' {
			doc /* From the operation back to the caller. */
		}
		enum 'inout' {
			doc /* Into the operation and back. */
		}
		enum result {
			doc /* The value that the operation returns. */
		}
	}

	#classType item def Generalization :> DirectedRelationship {
		doc /* The relationship from a more specific classifier to a more general one, whose features it inherits. */
		ref item specific : Classifier :> sources {
			doc /* The classifier that specializes. */
		}
		ref item general : Classifier :> targets {
			doc /* The classifier that is specialized. */
		}
		ref item generalizationSet : GeneralizationSet[0..1] {
			doc /* The set that groups this generalization with its siblings, if any. */
		}
	}

	#classType item def GeneralizationSet :> ModelElement {
		doc /* A named group of the generalizations of one general classifier. */
		attribute isCovering : Boolean {
			doc /* True when every instance of the general classifier is an instance of one of the specific classifiers. */
		}
		attribute isDisjoint : Boolean {
			doc /* True when no instance belongs to more than one of the specific classifiers. */
		}
	}

	#classType item def InterfaceRealization :> DirectedRelationship {
		doc /* The relationship from a classifier to an interface type whose contract it implements. */
		ref item implementingClassifier : Classifier :> sources {
			doc /* The classifier that implements the contract. */
		}
		ref item contract : InterfaceType :> targets {
			doc /* The interface type that states the contract. */
		}
	}

	#classType item def Association :> Relationship, Classifier {
		doc
		/*
		A relationship between classifiers whose instances are links between their instances; each end says how many
		instances take part and whether they can be reached.
		*/
		ref item :>> relatedElements : Classifier[2..*] {
			doc /* The classifiers at the ends of the association. */
		}
		item memberEnds : AssociationEnd[2..*] ordered {
			doc /* The ends of the association, one for each participating classifier. */
		}
	}

	#classType item def AssociationEnd :> StructuralFeature {
		doc /* One end of an association: the participating classifier, its multiplicity and its navigability. */
		attribute isNavigable : Boolean {
			doc /* True when the instances at this end can be reached from the instances at the other ends. */
		}
		attribute aggregation : AggregationKind {
			doc /* Whether this end is a part of the object at the other end, and whether that object owns its lifetime. */
		}
	}

	enum def AggregationKind {
		doc /* Whether an association end is a part of a whole, and whether the whole owns the part's lifetime. */
		enum noAggregation {
			doc /* The end is not part of a whole. */
		}
		enum sharedAggregation {
			doc /* The end is part of a whole that does not own its lifetime. */
		}
		enum compositeAggregation {
			doc /* The end is part of a whole that owns its lifetime: deleting the whole deletes the part. */
		}
	}

	#classType item def AssociationClass :> Association, Class {
		doc /* An association that is also a class: every link is an object with attributes and operations of its own. */
	}

	#classType item def Dependency :> DirectedRelationship {
		doc
		/*
		A relationship stating that the source elements need the target elements for their specification or
		implementation, in the way its kind says.
		*/
		attribute kind : DependencyKind {
			doc /* How the sources need the targets. */
		}
	}

	enum def DependencyKind {
		doc /* The ways in which the sources of a dependency need its targets. */
		enum usage {
			doc /* The sources use the targets in their implementation. */
		}
		enum creation {
			doc /* The sources create instances of the targets. */
		}
		enum call {
			doc /* The sources call operations of the targets. */
		}
		enum trace {
			doc /* The sources are traced to the targets, which they come from or answer. */
		}
		enum refinement {
			doc /* The sources state the targets more precisely. */
		}
		enum derivation {
			doc /* The sources can be computed from the targets. */
		}
	}

	#classType item def Constraint :> ModelElement {
		doc /* A condition, stated as a Boolean expression, that the constrained elements satisfy, such as a class invariant. */
		attribute specification : String {
			doc /* The expression, written in the expression language of the implementation. */
		}
		ref item constrainedElements : ModelElement[1..*] {
			doc /* The elements that the condition constrains. */
		}
	}
}
