import { MODULE_ID, log } from "./shared.js";
import { registerSettings } from "./settings.js";

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
        
        // Add your initialization logic here
        // Example: Initialize UI, register helpers, set up event listeners, etc.
        
    } catch (err) {
        console.error(`[${MODULE_ID}] Error during ready hook:`, err);
    }
});

// Example: Hook into combat tracker rendering
/*
Hooks.on("renderCombatTracker", (app, html, data) => {
    log("Combat tracker rendered");
    // Add custom UI elements or modify the combat tracker
});
*/

// Example: Hook into actor sheet rendering
/*
Hooks.on("renderActorSheet", (app, html, data) => {
    log("Actor sheet rendered for:", app.actor.name);
    // Add custom buttons or modify actor sheets
});
*/

// Example: Hook into chat messages
/*
Hooks.on("createChatMessage", (message, options, userId) => {
    log("Chat message created:", message.content);
    // Process chat messages or add custom functionality
});
*/

console.log(`[${MODULE_ID}] Core hooks registered`);
