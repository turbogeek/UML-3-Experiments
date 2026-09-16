# UML-3-Experiments

Experiments that bring UML-like capabilities to SysML v2: object-oriented analysis, software design and architecture, messaging, and data/database modeling. Everything is built as a **KerML/SysML v2 model library plus semantic metadata keywords**. The language grammar is not changed, so the models stay standard SysML v2.

```sysml
package Shop {
    private import ScalarValues::*;
    private import UML3Core::*;
    private import UML3Types::*;
    private import UML3Data::*;

    #entity item def Customer {                     // implies Customer :> UML3Data::Entity :> UML3Core::Class
        #primaryKey attribute customerId : Uuid;
        #unique attribute email : EmailAddress;
        #operation action changeEmail { in newEmail : EmailAddress; }
    }
}
```

## Layout

| Path | Contents |
|---|---|
| `library/UML3Core.sysml` | Classes, interfaces, operations, associations, generalization sets, templates, dependencies |
| `library/UML3Types.sysml` | Sized and formatted software types plus `@Facets` |
| `library/UML3Components.sysml` | Components, provided/required ports, connectors, layers, artifacts, nodes, deployment |
| `library/UML3Messaging.sysml` | Message schemas, channels/topics/queues, producer/consumer ports, QoS, serialization |
| `library/UML3Data.sysml` | Entities, relationships, keys, tables/columns/views, logical→physical mapping |
| `examples/` | One online-store domain: class model, architecture, messaging, database |
| `tests/negative/` | Models that must fail, each with an `EXPECT:` header |
| `tools/check_names.py` | Name-resolution checker (the ANTLR validator doesn't resolve names) |
| `tools/run_tests.py` | Regression harness; writes `logs/test-report.json` |
| `tools/pilot-check/` | Headless checker for the OMG Pilot Implementation (needs a working Pilot build) |
| `docs/DESIGN.md` | Design rationale, full UML → SysML v2 mapping, verification status, open questions |

## Running the tests

This repo expects sibling checkouts of `SysML-v2-Release` and `sysml-validator` (with `validator-cli/target/sysml-validator.jar` built). You can override their locations with `SYSML_RELEASE` and `SYSML_VALIDATOR_JAR`.

```bash
python tools/run_tests.py
```

The harness has four suites:
1. Syntax on the library and examples.
2. Name resolution on the library and examples.
3. Negative tests, each of which must fail with its expected code.
4. Checker calibration against the official OMG models, which must produce 0 findings.

## Using the library in a model

Load the `library/` files together with your model. Then import only the packages you need. A keyword is visible only when its package is imported, and the checker reports a missing import.
