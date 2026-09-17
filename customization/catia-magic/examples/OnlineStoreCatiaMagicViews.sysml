package OnlineStoreCatiaMagicViews {
	doc
	/*
	The online store's class views as CATIA Magic symbolic views with the UML3 palettes
	(UML3CatiaMagic). They expose the same content as the tool-neutral views of example 05, so diagrams look
	the same, and they add palettes whose buttons create UML3 elements.

	Contents:
	- domainClasses: the compact class diagram of OnlineStoreDomain.
	- domainClassDetails: the detail class diagram of OnlineStoreDomain.
	References: examples/05-OnlineStoreViews.sysml; UML3CatiaMagic; E17.
	*/

	private import UML3CatiaMagic::*;

	view domainClasses : 'UML3 Class Diagram' {
		doc /* The compact class diagram of the store's domain, drawn with the UML3 class palette. */
		expose OnlineStoreDomain::*;
	}

	view domainClassDetails : 'UML3 Class Detail Diagram' {
		doc /* The detail class diagram of the store's domain, drawn with the UML3 class palette. */
		expose OnlineStoreDomain::*;
	}
}
