package DogFoodToolchain {
	doc
	/*
	DogFoodToolchain: the tools that verify SysUML, their contracts, how the test runner wires them, and the
	workstation they run on. Each component stands for a file of the repository or of a sibling repository.

	Contents:
	- CheckReport, ModelChecker, CheckerPort: what every checker does and the port that carries it.
	- TestHarnessApi, HarnessPort: the REST interface of the CATIA Magic test harness (port 8770).
	- NameChecker, RuleChecker, DocumentationChecker, RequirementChecker, AntlrValidator, CameoCheck: the checkers.
	- CatiaMagicTestHarness: the harness that loads, validates and probes models inside CATIA Magic.
	- TestRunner: tools/run_tests.py, which runs every checker and reports the suites.
	- VerificationToolchain: the subsystem that wires the runner to the checkers and CameoCheck to the harness.
	- ToolScript, PythonRuntime, JavaRuntime, CatiaMagic, Workstation, developerWorkstation: where the tools run.
	References: tools/run_tests.py; tools/cameo_check.py; docs/DESIGN.md.
	*/
	private import ScalarValues::*;
	private import UML3Core::*;
	private import UML3Components::*;
	private import DogFoodImplementations::*;

	#dataType attribute def CheckReport {
		doc /* The machine-readable result of one check, as written to logs/. */
		attribute passed : Boolean {
			doc /* True when the check found nothing it counts as a failure. */
		}
		attribute findings : Integer {
			doc /* The number of findings. */
		}
		attribute reportFile : String {
			doc /* The report file under logs/. */
		}
	}

	#interfaceType item def ModelChecker {
		doc /* The contract of every checker: check model files and report. */
		abstract #operation action check {
			doc /* Checks the given model files and returns the report. */
			in models : ModelFile[1..*];
			out report : CheckReport;
		}
	}

	port def CheckerPort :> ServicePort {
		doc /* The port for the ModelChecker contract. */
		ref item :>> contract : ModelChecker;
	}

	#interfaceType item def TestHarnessApi {
		doc /* The REST interface of the CATIA Magic test harness, one operation per endpoint. */
		abstract #operation action status {
			doc /* GET /status: whether the harness is running. */
			out running : Boolean;
		}
		abstract #operation action loadSysML {
			doc /* POST /load-sysml: parses, links and validates a file and copies it into the open project. */
			in filePath : String;
			out success : Boolean;
		}
		abstract #operation action runScript {
			doc /* POST /run-script: runs a Groovy script from the harness scripts directory. */
			in scriptName : String;
			out result : String;
		}
		abstract #operation action shutdown {
			doc /* POST /shutdown: stops the harness, which frees the cached script classes. */
		}
	}

	port def HarnessPort :> ServicePort {
		doc /* The port for the TestHarnessApi contract. */
		ref item :>> contract : TestHarnessApi;
	}

	#component part def NameChecker {
		doc /* tools/check_names.py: names, keywords and their applicability, and reserved words. */
		@Technology { technologyName = "Python"; technologyVersion = "3.14"; }
		#provided port checking : CheckerPort {
			doc /* Provides ModelChecker. */
		}
	}

	#component part def RuleChecker {
		doc /* tools/check_rules.py: the UML3 design rules R01 to R16. */
		@Technology { technologyName = "Python"; technologyVersion = "3.14"; }
		#provided port checking : CheckerPort {
			doc /* Provides ModelChecker. */
		}
	}

	#component part def DocumentationChecker {
		doc /* tools/check_docs.py: the documentation rules D01 to D07. */
		@Technology { technologyName = "Python"; technologyVersion = "3.14"; }
		#provided port checking : CheckerPort {
			doc /* Provides ModelChecker. */
		}
	}

	#component part def RequirementChecker {
		doc /* tools/check_requirements.py: form, evidence, realization, use cases and the generated catalog. */
		@Technology { technologyName = "Python"; technologyVersion = "3.14"; }
		#provided port checking : CheckerPort {
			doc /* Provides ModelChecker. */
		}
	}

	#component part def AntlrValidator {
		doc /* The sysml-validator command line tool: SysML v2 syntax checked with an ANTLR grammar. */
		@Technology { technologyName = "Java"; technologyVersion = "21"; }
		#provided port checking : CheckerPort {
			doc /* Provides ModelChecker. */
		}
	}

	#service part def CatiaMagicTestHarness {
		doc /* The SysML v2 test harness running inside CATIA Magic, reached over REST on port 8770. */
		@Technology { technologyName = "Groovy"; technologyVersion = "5.0"; }
		#provided port harness : HarnessPort {
			doc /* Provides TestHarnessApi. */
		}
	}

	#component part def CameoCheck {
		doc
		/*
		tools/cameo_check.py: loads models into CATIA Magic through the harness, runs the validation engine, the
		probes, the implied-specialization hypotheses and the evaluation cases, and undoes the loads.
		*/
		@Technology { technologyName = "Python"; technologyVersion = "3.14"; }
		#provided port checking : CheckerPort {
			doc /* Provides ModelChecker, the authoritative check. */
		}
		#required port harness : ~HarnessPort {
			doc /* Requires TestHarnessApi. */
		}
	}

	#component part def TestRunner {
		doc /* tools/run_tests.py: runs every checker over the libraries, examples, requirements and this model. */
		@Technology { technologyName = "Python"; technologyVersion = "3.14"; }
		#required port syntax : ~CheckerPort {
			doc /* Requires the ANTLR validator. */
		}
		#required port names : ~CheckerPort {
			doc /* Requires the name checker. */
		}
		#required port rules : ~CheckerPort {
			doc /* Requires the rule checker. */
		}
		#required port docs : ~CheckerPort {
			doc /* Requires the documentation checker. */
		}
		#required port requirements : ~CheckerPort {
			doc /* Requires the requirement checker. */
		}
		#required port cameo : ~CheckerPort {
			doc /* Requires CameoCheck, used with --cameo. */
		}
	}

	#subsystem part def VerificationToolchain {
		doc /* The test runner wired to the checkers, and CameoCheck wired to the harness. */
		part runner : TestRunner {
			doc /* The test runner. */
		}
		part validator : AntlrValidator {
			doc /* The syntax check. */
		}
		part nameChecker : NameChecker {
			doc /* The name check. */
		}
		part ruleChecker : RuleChecker {
			doc /* The design-rule check. */
		}
		part docChecker : DocumentationChecker {
			doc /* The documentation check. */
		}
		part requirementChecker : RequirementChecker {
			doc /* The requirement check. */
		}
		part cameoCheck : CameoCheck {
			doc /* The check in CATIA Magic. */
		}
		part harness : CatiaMagicTestHarness {
			doc /* The harness inside CATIA Magic. */
		}
		#assembly connect runner.syntax to validator.checking;
		#assembly connect runner.names to nameChecker.checking;
		#assembly connect runner.rules to ruleChecker.checking;
		#assembly connect runner.docs to docChecker.checking;
		#assembly connect runner.requirements to requirementChecker.checking;
		#assembly connect runner.cameo to cameoCheck.checking;
		#assembly connect cameoCheck.harness to harness.harness;
	}

	#artifact item def ToolScript {
		doc /* A tool of the toolchain as a file of the repository. */
	}

	#executionEnvironment part def PythonRuntime {
		doc /* The Python interpreter that runs the Python tools. */
		@Technology { technologyName = "Python"; technologyVersion = "3.14"; }
	}

	#executionEnvironment part def JavaRuntime {
		doc /* The Java runtime that runs the ANTLR validator. */
		@Technology { technologyName = "Java"; technologyVersion = "21"; }
	}

	#executionEnvironment part def CatiaMagic {
		doc /* CATIA Magic with the SysML v2 plugin and its evaluation plugin, hosting the test harness. */
		@Technology { technologyName = "CATIA Magic"; technologyVersion = "2026x Refresh1"; }
	}

	#device part def Workstation {
		doc /* The developer workstation that runs the toolchain. */
		part python : PythonRuntime {
			doc /* Runs the Python tools. */
		}
		part java : JavaRuntime {
			doc /* Runs the validator. */
		}
		part catiaMagic : CatiaMagic {
			doc /* Runs the harness. */
		}
	}

	part developerWorkstation {
		doc /* The toolchain as it runs today: the scripts that implement it and where they are deployed. */
		part toolchain : VerificationToolchain {
			doc /* The logical toolchain. */
		}
		item runTestsScript : ToolScript {
			doc /* tools/run_tests.py. */
		}
		item harnessScript : ToolScript {
			doc /* start-v2language-test-harness.groovy in the sysml-validator repository. */
		}
		part machine : Workstation {
			doc /* The workstation. */
		}
		comment ToolDeployment about toolchain, runTestsScript, harnessScript, machine
			/*
			Manifestation and deployment. The test runner is implemented by tools/run_tests.py, which runs in the
			Python runtime; the harness is implemented by its Groovy script, which runs inside CATIA Magic.
			References: UML3Components::Manifestation; UML3Components::Deployment.
			*/
		#manifest allocate toolchain.runner to runTestsScript;
		#manifest allocate toolchain.harness to harnessScript;
		#deploy allocate runTestsScript to machine.python;
		#deploy allocate harnessScript to machine.catiaMagic;
	}
}
