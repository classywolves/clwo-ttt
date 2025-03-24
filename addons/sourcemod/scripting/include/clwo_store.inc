#if defined _clwo_store_included
    #endinput
#endif
#define _clwo_store_included

/*
 * Called when a clients skill is loaded or updated.
 *
 * @param client        The Client who purchased the item.
 * @param count         The Level of the Skill.
 */
typedef Store_SkillUpdateCallback = function void (int client, int level);

/*
 * Called when a clients skill is loaded or updated.
 *
 * @param client        The Client who purchased the item.
 * @param count         The Level of the Skill.
 */
typedef Store_UpgradeUpdateCallback = function void (int client, bool has);

/*
 * Called when the store is ready to register items.
 * Allows for the plugin to be reloaded.
 */
forward void Store_OnRegister();

/*
 * Called when the store has registered all items.
 */
forward void Store_OnReady();

forward void Store_OnClientSkillsLoaded(int client);

/*
 * Checkes for whether the store is ready yet.
 *
 * @return                  Whether the store is ready yet.
 */
native bool Store_IsReady();

/*
 * Registers a skill to the store.
 *
 * @param id                The short-tag identifier of the skill (must be unique).
 * @param name              The name of the skill.
 * @param description       The information about the skill.
 * @param price             The price of the skill.
 * @param step              The increase in price per level. (0.0 - No change)
 * @param level             The optional max level of this skill. (Default: 1, 0 - No limit)
 * @param callback          The function to call when this skill is loaded / updated.
 * @param sort              The priority in Sorting. Buy menu is sorted from high to low. (Default: 0)
 *
 * @return                  The items unique integer id for this session.
 */
native void Store_RegisterSkill(char[] id, char[] name, char[] description, int price, float step, int level, Store_SkillUpdateCallback callback, int sort = 0);

/*
 * Un-registers a skill from the store.
 *
 * @param id                The short-tag identifier of the item.
 *
 * @return                  Whether the item was succesfully removed.
 */
native bool Store_UnRegisterSkill(char[] id);

/*
 * Gets the level of this skill for the given client.
 *
 * @param client            The client to be checked.
 * @param id                The skills unique id.
 *
 * @return                  The count the user has of this item.
 */
native int Store_GetSkill(int client, char[] id);

/*
 * Registers a upgrade to the store.
 *
 * @param id                The short-tag identifier of the upgrade (must be unique).
 * @param name              The name of the upgrade.
 * @param description       The information about the upgrade.
 * @param price             The price of the upgrade.
 * @param callback          The function to call when this skill is loaded / updated.
 * @param sort              The priority in Sorting. Buy menu is sorted from high to low. (Default: 0)
 *
 * @return                  The items unique integer id for this session.
 */
native void Store_RegisterUpgrade(char[] id, char[] name, char[] description, int price, Store_UpgradeUpdateCallback callback, int sort = 0);

/*
 * Un-registers a upgrade from the store.
 *
 * @param id                The short-tag identifier of the item.
 *
 * @return                  Whether the item was succesfully removed.
 */
native bool Store_UnRegisterUpgrade(char[] id);

stock bool Store_CheckLibraryExists()
{
    return LibraryExists("clwo-store");
}

stock bool Store_CheckLibraryName(const char[] name)
{
    return strcmp(name, "clwo-store", true) == 0;
}

public SharedPlugin __pl_clwo_store =
{
    name = "clwo-store",
    file = "clwo_store.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_clwo_store_SetNTVOptional()
{
    MarkNativeAsOptional("Store_IsReady");

    MarkNativeAsOptional("Store_RegisterSkill");
    MarkNativeAsOptional("Store_UnRegisterSkill");
    MarkNativeAsOptional("Store_GetSkill");
    MarkNativeAsOptional("Store_RegisterUpgrade");
    MarkNativeAsOptional("Store_UnRegisterUpgrade");
}
#endif
