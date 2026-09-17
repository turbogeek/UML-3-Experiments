package ProjectViewCreationConfig {
	doc
	/*
	Activates the UML3 Create View dialog for the project: the Create View command then offers the UML3
	diagram kinds next to the predefined ones. CATIA Magic writes this package itself when the dialog is
	chosen in Options > Manage Create View Dialog; loading this file does the same thing, and only one
	View Creation dialog can be active.

	Usage: load it after customization/catia-magic/UML3CatiaMagic.sysml and reload the project. Remove the
	package to go back to the predefined dialog.

	Contents:
	- uml3ProjectViewCreationDialogConfig: the configuration that makes UML3ViewCreationDialog active.
	References: CATIA Magic SysML v2 Plugin 2026x R1 'Activating View Creation dialog'; UML3CatiaMagic.
	*/
	part def uml3ProjectViewCreationDialogConfig :> DS_UIComponents::CoreUIComponents::Dialogs::ViewCreationDialogConfiguration {
		doc /* The active View Creation dialog of this project: the UML3 one. */
		part : UML3CatiaMagic::UML3ViewCreationDialog :>> activeViewCreationDialog {
			doc /* Makes UML3CatiaMagic::UML3ViewCreationDialog the active Create View dialog. */
		}
	}
}
