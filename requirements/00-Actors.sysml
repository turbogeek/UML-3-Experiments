package UML3Actors {
	doc
	/*
	UML3Actors: the roles that use UML3, and the subject of the UML3 use cases.

	Every UML3 use case names its actors from this package and uses UML3Environment as its subject: UML3 with
	its libraries, checkers, generators and the SysML v2 tools that host it.

	Contents:
	- Subject: UML3Environment.
	- Engineering roles: SoftwareArchitect, SoftwareDeveloper, DataModeler, IntegrationEngineer, TestEngineer,
	  DevOpsEngineer, SecurityEngineer, SystemsEngineer.
	- Stakeholder and review roles: ProductOwner, Reviewer, TechnicalWriter.
	- Ecosystem roles: ToolVendor, LanguageMaintainer, AIAssistant.
	References: SysML 7.25.
	*/

	part def UML3Environment {
		doc
		/*
		The system under consideration in UML3 use cases: the UML3 language definition and libraries, the UML3
		checkers and generators, and the SysML v2 modeling tool that hosts them.
		*/
	}

	part def SoftwareArchitect {
		doc /* Designs the structure of software systems: components, services, interfaces, deployment and architecture decisions. */
	}
	part def SoftwareDeveloper {
		doc /* Designs classes and behavior in detail, and implements software from the model or keeps code and model aligned. */
	}
	part def DataModeler {
		doc /* Designs conceptual, logical and physical data models, schemas and their mappings. */
	}
	part def IntegrationEngineer {
		doc /* Designs message contracts, event flows and APIs between services and systems. */
	}
	part def TestEngineer {
		doc /* Plans and designs tests of the software, links them to requirements and design, and reports results. */
	}
	part def DevOpsEngineer {
		doc /* Designs build and delivery pipelines, environments, infrastructure and operations of the software. */
	}
	part def SecurityEngineer {
		doc /* Analyzes threats, classifies data and specifies and verifies security controls. */
	}
	part def SystemsEngineer {
		doc /* Models the system that contains the software in SysML v2 and allocates functions and requirements to software. */
	}
	part def ProductOwner {
		doc /* States the needs and acceptance criteria the software has to meet and validates the design against them. */
	}
	part def Reviewer {
		doc /* Reviews models, reports and generated artifacts for correctness, completeness and compliance. */
	}
	part def TechnicalWriter {
		doc /* Produces specifications, user and developer documentation from the model. */
	}
	part def ToolVendor {
		doc /* Implements UML3 support in a modeling tool, generator or analysis tool and claims conformance. */
	}
	part def LanguageMaintainer {
		doc /* Maintains the UML3 language definition, libraries, documentation and conformance tests. */
	}
	part def AIAssistant {
		doc
		/*
		An AI system that drafts, reviews, explains or transforms UML3 models on behalf of a human user, under
		that user's review.
		*/
	}
}
