#if defined _special_days_included
#endinput
#endif
#define _special_days_included

public SharedPlugin __pl_special_days =
{
    name = "special-days",
    file = "special-days.smx",
#if defined REQUIRE_PLUGIN
    required = 1
#else
    required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_special_days_SetNTVOptional()
{
    MarkNativeAsOptional("SD_StartSpecialDay");
    MarkNativeAsOptional("SD_StopSpecialDay");
    MarkNativeAsOptional("SD_IsSpecialDayRunning");
    MarkNativeAsOptional("SD_IsSpecialDay");
}
#endif

/*
 * Called when a new special day is meant to start.
 *
 * @param id         The id of the special day to start.
 */
forward void SD_StartSpecialDay(char[] id);

/*
 * Called when a new special day is meant to stop.
 */
forward void SD_StopSpecialDay();

/*
 * Registers a special day.
 *
 * @param id                The short-tag identifier of the special day (must be unique).
 * @param name              The name of the special day.
 * @param description       The description of the sepcial day.
 */
native void SD_RegisterSpecialDay(char[] id, char[] name, char[] description);

native bool SD_IsSpecialDay();
