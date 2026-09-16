# pilot-check (not yet operational)

`SysMLCheck.groovy` runs the OMG Pilot Implementation (`SysMLInteractive`) headlessly. It does full semantic validation: linking, typing, and the specialization implied by semantic metadata. That covers the checks that `tools/check_names.py` cannot do.

Status on 2026-09-16: **not verified**. The local `SysML-v2-Pilot-Implementation` build (0.55.0-SNAPSHOT) contains class files with "Unresolved compilation problems", so loading it fails with `NoClassDefFoundError: Resource`.

To enable it, either:
* rebuild the Pilot Implementation successfully (`mvnw clean package` in the Pilot checkout), or
* obtain the `org.omg.sysml.interactive-<version>-all.jar` or `jupyter-sysml-kernel` jar that matches the `SysML-v2-Release` version (2026-03 / 0.58).

Then run:

```bash
groovy -cp <all-jar> tools/pilot-check/SysMLCheck.groovy <SysML-v2-Release>/sysml.library logs/pilot-report.json library examples
```
