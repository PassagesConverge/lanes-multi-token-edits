// MODULE IDENTIFIER - Replace with your module's ID (must match module.json)
export const MODULE_ID = "lanes-multi-token-edits";

/**
 * Helper logging function that prints debug messages if logging is enabled.
 * Falls back gracefully if settings are not registered.
 */
export function log(...args) {
  try {
    if (game.settings.get(MODULE_ID, "enableLogging")) {
      console.log(`[${MODULE_ID}]`, ...args);
    }
  } catch (err) {
    console.log(`[${MODULE_ID}] (log fallback)`, ...args);
  }
}

/**
 * Helper function to generate unique IDs
 */
export function generateId(prefix = "id") {
  return `${prefix}-` + foundry.utils.randomID();
}
