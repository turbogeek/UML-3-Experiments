// Lists the AWT/Swing windows CATIA Magic currently has, so a run that appears to hang can be told apart from one
// waiting behind a modal dialog. Read-only: it shows nothing, closes nothing, and needs no session.
// It deliberately does NOT touch the event dispatch thread, so it still answers while the EDT is busy.
// Output lines (no System.exit):
//   EDT|busy=<true/false>                          WINDOW|<class>|<title>|visible=<b>|modal=<b>|focused=<b>
//   TEXT|<window title>|<label or button text>     RESULT|OK|<window count>
import javax.swing.SwingUtilities

def out = new StringBuilder()
def clean = { Object t -> t == null ? "null" : t.toString().replace("|", "/").replace("\r", "").replace("\n", " ") }
def call0 = { Object o, String m -> try { (o != null && o.respondsTo(m)) ? o."$m"() : null } catch (Throwable t) { null } }

// is the EDT free? ask it to do nothing, with a short wait - never block the harness on a frozen EDT
boolean edtBusy = true
try {
    def done = new java.util.concurrent.CountDownLatch(1)
    SwingUtilities.invokeLater({ done.countDown() } as Runnable)
    edtBusy = !done.await(3, java.util.concurrent.TimeUnit.SECONDS)
} catch (Throwable t) { }
out.append("EDT|busy=" + edtBusy + "\n")

def windows = java.awt.Window.getWindows() ?: new java.awt.Window[0]
int shown = 0
windows.each { w ->
    boolean visible = false
    try { visible = w.isVisible() } catch (Throwable t) { }
    if (!visible) return
    shown++
    def title = call0(w, "getTitle")
    out.append("WINDOW|" + w.getClass().getSimpleName() + "|" + clean(title) + "|visible=true|modal=" +
        clean(call0(w, "isModal")) + "|focused=" + clean(call0(w, "isFocused")) + "\n")
    // a dialog that blocks a run usually says why: collect the labels and buttons inside it
    if (call0(w, "isModal") == Boolean.TRUE || w.getClass().getSimpleName().contains("Dialog")) {
        def texts = []
        def walk
        walk = { java.awt.Container c, int depth ->
            if (depth > 8) return
            c.getComponents().each { comp ->
                def t = call0(comp, "getText")
                if (t instanceof String && !((String) t).trim().isEmpty()) texts << ((String) t).trim()
                if (comp instanceof java.awt.Container) walk((java.awt.Container) comp, depth + 1)
            }
        }
        try { walk(w, 0) } catch (Throwable t) { }
        texts.unique().take(25).each { out.append("TEXT|" + clean(title) + "|" + clean(it) + "\n") }
    }
}
return out.append("RESULT|OK|" + shown + "\n").toString()
