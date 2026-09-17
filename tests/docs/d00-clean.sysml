package DocsClean {
	doc
	/*
	A package whose every element is documented.
	Contents:
	- Engine: a documented part definition.
	References: KerML 7.2.4.2.
	*/

	part def Engine {
		doc
		/*
		A documented part definition.
		References: SysML 7.11.
		*/
		attribute power : ScalarValues::Real { doc /* Rated power. */ }
	}

	comment EngineDesign about Engine, Engine::power
		/*
		Explains how the engine and its power attribute work together.
		*/
}
