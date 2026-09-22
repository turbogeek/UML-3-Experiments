package DMMFoundation {
	doc
	/*
	DMMFoundation: what every element of a UML-level software model has, whatever its kind: an identity that
	survives renaming and the round trip, names, documentation and visibility, ownership by namespaces and packages,
	and relationships between elements.

	Contents:
	- ModelElement: the root concept.
	- VisibilityKind: public, protected and private membership.
	- Namespace, Package: elements that own other elements.
	- Relationship, DirectedRelationship: elements that relate other elements.
	References: KerML 7.2; UML 2.5.1 Package; UML 2.5.1 VisibilityKind; UML 2.5.1 Dependency.
	*/
	private import ScalarValues::*;
	private import UML3Core::*;

	abstract #classType item def ModelElement {
		doc
		/*
		Anything that a UML-level software model contains. An element is identified independently of its names, so
		it keeps its identity when it is renamed, versioned or moved between the two implementations.
		*/
		attribute identifier : String {
			doc /* The identifier that stays with the element through renaming, versions and the round trip. */
		}
		attribute name : String[0..1] {
			doc /* The name by which other elements refer to this one; many relationships have none. */
		}
		attribute shortName : String[0..1] {
			doc /* A second, shorter name, such as a requirement identifier. */
		}
		attribute documentation : String[0..*] ordered {
			doc /* The documentation texts that the element owns. */
		}
		attribute visibility : VisibilityKind {
			doc /* Who may refer to the element by name from outside the namespace that owns it. */
		}
	}

	enum def VisibilityKind {
		doc /* Who may refer to an element by name from outside the namespace that owns it. */
		enum 'public' {
			doc /* Any namespace. */
		}
		enum 'protected' {
			doc /* The owning namespace and the namespaces that specialize it. */
		}
		enum 'private' {
			doc /* The owning namespace and the namespaces nested in it. */
		}
	}

	abstract #classType item def Namespace :> ModelElement {
		doc /* An element that owns other elements and may make the visible members of other namespaces its own. */
		item ownedElements : ModelElement[0..*] ordered {
			doc /* The elements that the namespace owns; deleting the namespace deletes them. */
		}
		ref item importedNamespaces : Namespace[0..*] {
			doc /* The namespaces whose visible members are members of this namespace too. */
		}
	}

	#classType item def Package :> Namespace {
		doc /* A namespace that groups the elements of a model for organization, reuse and access control. */
	}

	abstract #classType item def Relationship :> ModelElement {
		doc /* An element that relates other elements, such as an association between classifiers. */
		ref item relatedElements : ModelElement[1..*] {
			doc /* All the elements that the relationship relates; specializations subset or redefine it. */
		}
	}

	abstract #classType item def DirectedRelationship :> Relationship {
		doc
		/*
		A relationship that goes from source elements to target elements, such as a generalization, which goes from
		the specific classifier to the general one, or a dependency.
		*/
		ref item sources : ModelElement[1..*] ordered :> relatedElements {
			doc /* The elements that the relationship goes from. */
		}
		ref item targets : ModelElement[1..*] ordered :> relatedElements {
			doc /* The elements that the relationship goes to. */
		}
	}
}
