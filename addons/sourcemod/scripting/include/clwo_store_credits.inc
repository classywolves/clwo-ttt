#if defined _clwo_store_credits_included
    #endinput
#endif
#define _clwo_store_credits_included

/*
 * Called when a player gains cR.
 *
 * @param client            The client who purchased the item.
 * @param credits           The amount of credits the player is to gain.
 */
forward Action Store_OnClientGainCredits(int client, int& credits);

/*
 * Gets the clients total credits.
 *
 * @param client            The client to be checked.
 *
 * @return                  The clients credit count.
 */
native int Store_GetClientCredits(int client);

/*
 * Sets the clients total credits.
 *
 * @param client            The client to be checked.
 * @param credits           The amount the clients credits should be set too.
 *
 * @return                  The clients credit count.
 */
native int Store_SetClientCredits(int client, int credits);

/*
 * Gets the clients total credits.
 *
 * @param client            The client to be checked.
 * @param credits           The amount of credits to be added to the clients total credits.
 *
 * @return                  The clients credit count.
 */
native int Store_AddClientCredits(int client, int credits);

/*
 * Gets the clients total credits.
 *
 * @param client            The client to be checked.
 * @param credits           The amount of credits to be subtracted from the clients total credits.
 *
 * @return                  The clients credit count.
 */
native int Store_SubClientCredits(int client, int credits);

stock bool Store_CheckCreditsLibraryExists()
{
    return LibraryExists("clwo-store-credits");
}

stock bool Store_CheckCreditsLibraryName(const char[] name)
{
    return strcmp(name, "clwo-store-credits", true) == 0;
}

stock bool Store_IsCreditAmountValid(int cr)
{
    return cr >= 0;
}

public SharedPlugin __pl_clwo_store =
{
    name = "clwo-store-credits",
    file = "clwo_store_credits.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_clwo_store_SetNTVOptional()
{
    MarkNativeAsOptional("Store_GetClientCredits");
    MarkNativeAsOptional("Store_SetClientCredits");
    MarkNativeAsOptional("Store_AddClientCredits");
    MarkNativeAsOptional("Store_SubClientCredits");
}
#endif
