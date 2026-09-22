package DogFoodUML3 {
	doc
	/*
	DogFoodUML3: the effort that builds SysUML and UML3, modeled in SysUML (requirement UML3-CORE-014).

	The effort is a software system of its own: the SysUML libraries with their CATIA Magic customization, the
	UML3 language still to be built, the transformation that is to connect the two, and the toolchain of
	checkers, validator, CATIA Magic test harness and test runner that verifies them. Modeling it with the SysUML
	keywords exercises SysUML on a real system; its satisfy and allocate relationships show which part of the
	effort meets, or is responsible for, which requirement.

	Contents:
	- DogFoodImplementations (01-Implementations.sysml): SysUML, UML3 and the round-trip transformation.
	- DogFoodToolchain (02-Toolchain.sysml): the checkers, the validator, the test harness and the test runner, the
	  contracts between them, their wiring, and the workstation they run on.
	- DogFoodTraceability (03-Traceability.sysml): the requirements that the elements of the effort satisfy or are
	  allocated to.
	- DomainMetamodel (DomainMetamodel/): the data architecture, a model of the underlying and the surface data of
	  UML-level software modeling that neither implementation dictates, with the SysUML element that realizes each
	  concept (UML3-IMPL-012).
	References: requirements/01-Core.sysml; requirements/22-Implementations.sysml; docs/DESIGN.md.
	*/
}
