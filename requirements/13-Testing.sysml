package UML3TestingRequirements {
	doc
	/*
	TEST: requirements on modeling the tests of the software that a UML3 model describes: test cases and
	suites, fixtures and test data, test doubles, traces to requirements and design elements, coverage, tests
	derived from behavior and contracts, performance and security tests, and test results.
	Verifying the UML3 model itself is in UML3VerificationRequirements (VER).

	Contents:
	- Test design: testCases, testSuites, fixturesAndTestData, testDoubles.
	- Traceability and coverage: requirementTests, designElementTests, testCoverage.
	- Derived and quality tests: testsFromBehavior, contractTests, performanceAndSecurityTests.
	- Results: testResults.
	- UseCases: how test engineers, developers, integration engineers and reviewers use test models.
	- Realization: no TEST requirement is done yet.
	References: docs/REQUIREMENTS-GUIDE.md; SysML 7.24.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;

	requirement <'UML3-TEST-001'> testCases {
		doc
		/*
		UML3 shall model a software test case as a native SysML v2 verification case whose subject is the element
		under test (an operation, class, component, subsystem or deployed system), whose objective states what
		the test verifies and whose result is a verdict.
		*/
		@Rationale { text = "SysML v2 verification cases already have a subject, an objective, verified requirements and a verdict; using them keeps software tests and system verification in one model."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-TEST-002'> testSuites {
		doc
		/*
		UML3 shall group test cases into test suites that can be nested and that state the setup and teardown
		shared by their test cases.
		*/
		@Rationale { text = "Tests are organized by level and component and share their setup; a model without suites cannot say which tests run together or how they are prepared."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-TEST-003'> fixturesAndTestData {
		doc
		/*
		UML3 shall model the fixture of a test case (the configuration and initial state of the element under test
		and its environment) and its test data (inputs and expected results), with individuals and snapshots of
		design elements as concrete values.
		*/
		@Rationale { text = "A test is reproducible only with its fixture and data, and SysML v2 individuals and snapshots already give concrete values with identity and time."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-TEST-004'> testDoubles {
		doc
		/*
		UML3 shall model test doubles (stubs, fakes and mocks) that replace a component, port or interface used by
		the element under test, and shall state the interactions that a mock expects.
		*/
		@Rationale { text = "Components and services are tested in isolation by replacing what they depend on; a double declared against the same interface or port stays consistent with the design."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-TEST-005'> requirementTests {
		doc
		/*
		Each test case shall trace to the requirements it verifies, and the test cases that verify a requirement
		shall be navigable from that requirement.
		*/
		@Rationale { text = "Traces between requirements and tests show that each requirement is tested and why each test exists."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
	}

	requirement <'UML3-TEST-006'> designElementTests {
		doc
		/*
		Each test case shall identify the design elements it exercises, such as operations, components, ports,
		message types, states and transitions.
		*/
		@Rationale { text = "When a design element changes, the tests to run again and update are the ones that exercise it."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
	}

	requirement <'UML3-TEST-007'> testCoverage {
		doc
		/*
		UML3 tooling shall report the coverage of requirements, operations, states, transitions and message types
		by test cases, and shall list the elements that no test case covers.
		*/
		@Rationale { text = "Coverage of the model shows untested design decisions before any code exists, and complements code coverage afterwards."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
	}

	requirement <'UML3-TEST-008'> testsFromBehavior {
		doc
		/*
		UML3 shall define how test cases are derived from state machines (for example one test case per
		transition) and from interactions (one test case per message sequence), and each derived test case shall
		trace to the behavior it was derived from.
		*/
		@Rationale { text = "State machines and interactions already state the expected behavior; deriving tests from them is systematic and keeps the tests aligned with the design."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-TEST-009'> contractTests {
		doc
		/*
		UML3 shall derive contract tests for interfaces, service ports and message types from their contracts
		(operations with their parameters, message schemas, serialization and quality of service), so that a
		provider and a consumer can each be tested alone against the same contract.
		*/
		@Rationale { text = "Services and event-driven systems break at their contracts; testing both sides against the modeled contract finds incompatibilities before integration."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-TEST-010'> performanceAndSecurityTests {
		doc
		/*
		UML3 shall specify performance tests, with load profiles and response time and throughput targets given as
		quantities with units, and security tests, with objectives traced to the threats and controls they check.
		*/
		@Rationale { text = "Quality requirements are verified by tests with measurable targets, and SysML v2 quantities and units make those targets exact."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-TEST-011'> testResults {
		doc
		/*
		The results of test runs shall be related to the test cases of the model, each result with its verdict,
		the version of the software tested and the time of the run, without changing the test cases.
		*/
		@Rationale { text = "Results make coverage and requirement status real, but they change on every run; whether they belong in the model or in external reports that it references is not decided."; }
		@StatusInfo { status = StatusKind::tbd; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	package UseCases {
		doc
		/*
		UseCases: how test engineers, developers, integration engineers and reviewers use test models.

		Contents:
		- DesignSoftwareTests: a test engineer designs test cases, suites, fixtures, data and doubles in the model.
		- TestServiceContracts: an integration engineer and a test engineer test services against their contracts
		  and quality targets.
		- AnalyzeTestCoverage: a test engineer derives tests from behavior, relates results and reports coverage
		  for a reviewer.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def DesignSoftwareTests {
			doc
			/*
			A test engineer and a software developer design the tests of the software in the model: test cases on
			the elements under test, suites with their setup, fixtures and test data, and test doubles, traced to
			the requirements they verify, the acceptance criteria they check and the design elements they exercise.
			*/
			subject environment : UML3Environment;
			actor tester : TestEngineer;
			actor developer : SoftwareDeveloper;
			objective {
				doc /* Every requirement has test cases that can be implemented without guessing their inputs, expected results or setup. */
			}
		}

		use case def TestServiceContracts {
			doc
			/*
			An integration engineer and a test engineer derive contract tests for the interfaces, ports and message
			types of services, replace the services' dependencies with test doubles, and specify performance and
			security tests with measurable targets.
			*/
			subject environment : UML3Environment;
			actor integrator : IntegrationEngineer;
			actor tester : TestEngineer;
			objective {
				doc /* Each service can be tested alone against its contracts and quality targets. */
			}
		}

		use case def AnalyzeTestCoverage {
			doc
			/*
			A test engineer derives test cases from state machines and interactions, relates the results of test
			runs to the test cases and reports what the tests cover; a reviewer uses the report to decide whether
			testing is sufficient.
			*/
			subject environment : UML3Environment;
			actor tester : TestEngineer;
			actor reviewer : Reviewer;
			objective {
				doc /* The untested requirements and design elements are known, and each result belongs to a test case and a tested version. */
			}
		}

		#traces dependency from DesignSoftwareTests to 'UML3-TEST-001', 'UML3-TEST-002', 'UML3-TEST-003', 'UML3-TEST-004',
			'UML3-TEST-005', 'UML3-TEST-006', UML3ValidationRequirements::'UML3-VAL-006';
		#traces dependency from TestServiceContracts to 'UML3-TEST-004', 'UML3-TEST-009', 'UML3-TEST-010';
		#traces dependency from AnalyzeTestCoverage to 'UML3-TEST-005', 'UML3-TEST-007', 'UML3-TEST-008', 'UML3-TEST-011',
			UML3VerificationRequirements::'UML3-VER-007';
	}

	package Realization {
		doc
		/*
		Realization: the library elements that realize the done TEST requirements.

		Contents:
		- None yet: UML3 has no testing library or testing example, so no TEST requirement is done and there are
		  no #realizes dependencies.
		*/
	}
}
