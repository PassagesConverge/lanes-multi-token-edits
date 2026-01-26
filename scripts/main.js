import { MODULE_ID, log } from "./shared.js";
import { registerSettings } from "./settings.js";
import { initMultiTokenEffects } from "./multi-token-effects.js";
import { initMultiTokenHealth } from "./multi-token-health.js";

/**
 * Initialize module on 'init' hook
 */
Hooks.once("init", () => {
    try {
        console.log(`[${MODULE_ID}] Initializing module...`);
        registerSettings();
        console.log(`[${MODULE_ID}] Module initialized successfully`);
    } catch (err) {
        console.error(`[${MODULE_ID}] Error during initialization:`, err);
    }
});

/**
 * Setup module on 'ready' hook
 */
Hooks.once("ready", () => {
    try {
        console.log(`[${MODULE_ID}] Module ready`);
        log("Module is fully loaded and ready");
        
        // Initialize multi-token effects
        initMultiTokenEffects();
        
        // Initialize multi-token health management
        initMultiTokenHealth();
        
    } catch (err) {
        console.error(`[${MODULE_ID}] Error during ready hook:`, err);
    }
});

console.log(`[${MODULE_ID}] Core hooks registered`);
