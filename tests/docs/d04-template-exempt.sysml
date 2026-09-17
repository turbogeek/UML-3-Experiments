package DocsTemplates {
	doc
	/*
	Element templates copied by palette buttons: template packages and their contents own no documentation.
	Contents:
	- classTemplate: an unnamed class definition to copy.
	- dependencyTemplate: a dependency between two placeholder definitions.
	*/
	package classTemplate { item def; }
	package dependencyTemplate {
		item def Client;
		item def Supplier;
		dependency from Client to Supplier;
	}
}
