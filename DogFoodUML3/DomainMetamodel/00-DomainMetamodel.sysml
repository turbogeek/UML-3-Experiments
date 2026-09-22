package DomainMetamodel {
	doc
	/*
	DomainMetamodel: the data architecture of UML-level software modeling, a model of the underlying data and the
	surface data of a model that neither implementation dictates (UML3-IMPL-012).

	The underlying data is what a model says: its elements, their features and the relationships between them. The
	surface data is how people write and see it: the keywords that mark elements, the diagram kinds and palettes
	that show and create them, and the presentations of particular elements. SysUML and UML3 are two realizations of
	this one model; each maps every concept to the construct that realizes it, which is what keeps their concepts
	aligned (UML3-IMPL-003) and what the lossless round trip preserves (UML3-IMPL-005).

	Conventions. The metamodel is written in SysUML, as a class model: each concept is a #classType item
	definition, a value without identity is a #dataType attribute definition or an enumeration, a composite feature
	owns its values and a ref feature refers to them, and a specialized feature subsets the general one. The
	concepts sit one level above the models they describe, although they are written as ordinary classes: the
	concept Class is a class whose instances are the classes of a user model. Where a concept has the name of a
	SysUML library element, such as Class, the concept owned here hides the imported element (KerML 7.2.5), and
	the realization maps use qualified names.

	Contents:
	- DMMFoundation (01-Foundation.sysml): identity, names, documentation, namespaces, packages and relationships.
	- DMMStructure (02-Structure.sysml): classifiers, features, operations and the relationships of a class model.
	- DMMSurface (03-Surface.sysml): keyword forms, diagram kinds, palette entries and presentations.
	- DMMSysUMLRealization (04-SysUMLRealization.sysml): the SysUML elements that realize each concept.
	References: KerML 7.2.5; SysML 7.6; requirements/22-Implementations.sysml; docs/DESIGN.md.
	*/
}
