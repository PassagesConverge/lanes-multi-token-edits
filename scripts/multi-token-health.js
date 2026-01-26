/****************************************************************************************
 * multi-token-health.js — Apply health changes to all selected tokens
 * --------------------------------------------------------------------------------------
 * Intercepts HP field edits on the Token HUD to apply changes to all selected tokens.
 ****************************************************************************************/

import { MODULE_ID, log } from "./shared.js";

/**
 * Initialize multi-token health management
 */
export function initMultiTokenHealth() {
    console.log(`[${MODULE_ID}] initMultiTokenHealth called`);
    
    // Hook into actor updates to intercept HP changes
    Hooks.on("preUpdateActor", interceptHPUpdate);
    
    // Hook into token HUD rendering to track which token triggered the update
    Hooks.on("renderTokenHUD", onRenderTokenHUD);
    
    console.log(`[${MODULE_ID}] ✅ Multi-token health management initialized`);
    log(`[${MODULE_ID}] ✅ Multi-token health initialized`);
}

let lastHUDToken = null;
let isApplyingGroupUpdate = false;

/**
 * Track which token's HUD is being displayed
 */
function onRenderTokenHUD(hud, html, data) {
    lastHUDToken = hud.object;
    console.log(`[${MODULE_ID}] Token HUD rendered for:`, lastHUDToken?.name);
}

/**
 * Intercept HP updates and apply to all selected tokens
 */
function interceptHPUpdate(actor, updateData, options, userId) {
    // Skip if we're already applying a group update to prevent loops
    if (isApplyingGroupUpdate) return true;
    // Only process if this is an HP update
    const hpPath = "system.attributes.hp.value";
    const hpPathAlt = "system.hp.value";
    
    const isHPUpdate = foundry.utils.hasProperty(updateData, hpPath) || 
                       foundry.utils.hasProperty(updateData, hpPathAlt);
    
    if (!isHPUpdate) return true;
    
    console.log(`[${MODULE_ID}] HP update detected for actor:`, actor.name);
    console.log(`[${MODULE_ID}] Update data:`, updateData);
    
    // Get the new HP value
    const newHP = foundry.utils.getProperty(updateData, hpPath) ?? 
                  foundry.utils.getProperty(updateData, hpPathAlt);
    
    if (newHP === undefined) return true;
    
    // Check if multiple tokens are selected
    const selectedTokens = canvas.tokens.controlled;
    console.log(`[${MODULE_ID}] Selected tokens:`, selectedTokens.length);
    
    if (selectedTokens.length <= 1) {
        return true; // Normal single token update
    }
    
    // Check if one of the selected tokens is being updated
    const updatingToken = selectedTokens.find(t => t.actor?.id === actor.id);
    if (!updatingToken) {
        return true; // Not updating a selected token
    }
    
    console.log(`[${MODULE_ID}] Applying HP update to ${selectedTokens.length} selected tokens`);
    
    // Get the old HP value to calculate the delta
    let oldHP = actor.system.attributes?.hp?.value ?? actor.system.hp?.value ?? 0;
    const delta = newHP - oldHP;
    
    console.log(`[${MODULE_ID}] HP change: ${oldHP} → ${newHP} (delta: ${delta})`);
    
    // Apply the same delta to all other selected tokens
    setTimeout(async () => {
        isApplyingGroupUpdate = true;
        
        try {
            // Batch updates to reduce conflicts
            const updates = [];
            
            for (const token of selectedTokens) {
                if (!token.actor || token.actor.id === actor.id) continue; // Skip the original
                
                try {
                    // Get current HP
                    let hpAttr = token.actor.system.attributes?.hp;
                    let tokenHpPath = "system.attributes.hp.value";
                    
                    if (!hpAttr) {
                        hpAttr = token.actor.system.hp;
                        tokenHpPath = "system.hp.value";
                    }
                    
                    if (!hpAttr) {
                        console.warn(`[${MODULE_ID}] Token ${token.name} has no HP attribute`);
                        continue;
                    }
                    
                    const currentHP = hpAttr.value ?? 0;
                    const maxHP = hpAttr.max ?? 0;
                    const tokenNewHP = Math.max(0, Math.min(maxHP, currentHP + delta));
                    
                    console.log(`[${MODULE_ID}] Updating ${token.name}: ${currentHP} → ${tokenNewHP}`);
                    
                    // Add to batch with slight delay between each to avoid race conditions
                    updates.push({
                        actor: token.actor,
                        path: tokenHpPath,
                        value: tokenNewHP
                    });
                    
                } catch (err) {
                    console.error(`[${MODULE_ID}] Failed to prepare update for ${token.name}:`, err);
                }
            }
            
            // Apply updates sequentially with small delays to avoid conflicts
            for (const update of updates) {
                try {
                    await update.actor.update(
                        { [update.path]: update.value },
                        { [MODULE_ID]: { batchUpdate: true } }
                    );
                    // Small delay between updates to let other modules process
                    await new Promise(resolve => setTimeout(resolve, 50));
                } catch (err) {
                    // Silently ignore ActiveEffect errors from other modules
                    if (!err.message?.includes("ActiveEffect") && !err.message?.includes("does not exist")) {
                        console.error(`[${MODULE_ID}] Failed to update actor:`, err);
                    }
                }
            }
            
            const verb = delta > 0 ? "healing" : "damage";
            const absAmount = Math.abs(delta);
            ui.notifications.info(`Applied ${absAmount} ${verb} to ${selectedTokens.length} selected token(s)`);
            
        } finally {
            isApplyingGroupUpdate = false;
        }
    }, 10);
    
    return true; // Allow the original update to proceed
}
