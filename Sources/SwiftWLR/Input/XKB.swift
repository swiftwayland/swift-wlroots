// TODO: I suppose that xkb-related things should be placed in a separate
// module.

import Cwlroots

public class XKBContext {
    let xkbContext: OpaquePointer

    public init() {
        self.xkbContext = xkb_context_new(XKB_CONTEXT_NO_FLAGS)
    }

    deinit {
        xkb_context_unref(xkbContext)
    }
}

public class XKBKeymap {
    let xkbKeymap: OpaquePointer

    public init(_ pointer: OpaquePointer) {
        self.xkbKeymap = pointer
    }

    public init(context: XKBContext) {
        var xkbRuleNames = xkb_rule_names()

        self.xkbKeymap = xkb_keymap_new_from_names(
            context.xkbContext,
            &xkbRuleNames,
            XKB_KEYMAP_COMPILE_NO_FLAGS
        )
    }

    deinit {
        xkb_keymap_unref(xkbKeymap)
    }
}
