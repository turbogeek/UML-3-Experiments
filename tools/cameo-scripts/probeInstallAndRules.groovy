// READ-ONLY diagnostic: install root and counts of active/system UML validation rules.
import com.nomagic.magicdraw.core.Application
import com.nomagic.magicdraw.validation.ValidationSuiteHelper

def sb = new StringBuilder()
def proj = Application.getInstance().getProject()
if (proj == null) return "NO_PROJECT"
try {
    def env = Class.forName("com.nomagic.magicdraw.core.ApplicationEnvironment", true, Application.getInstance().getClass().getClassLoader())
    sb.append("installRoot=" + env.getMethod("getInstallRoot").invoke(null) + "\n")
} catch (Throwable t) {
    sb.append("installRoot via ApplicationEnvironment failed: " + t + "\n")
}
sb.append("user.dir=" + System.getProperty("user.dir") + "\n")
def helper = ValidationSuiteHelper.getInstance(proj)
["getActiveValidationSuites", "getSuitesForPassiveValidation", "getSystemValidationRules", "getUserSelectedActiveValidationSuites"].each { m ->
    try {
        def v = helper."$m"()
        sb.append(m + " -> " + (v == null ? "null" : v.size()) + "\n")
    } catch (Throwable t) {
        sb.append(m + " threw " + t + "\n")
    }
}
return sb.toString()
