#if defined _special_days_included
#endinput
#endif
#define _special_days_included

#define SPECIAL_DAY_COUNT 3
#define SPECIAL_DAY_BHOP 0
#define SPECIAL_DAY_OITC 1
#define SPECIAL_DAY_KOTH 2
#define SPECIAL_DAY_DOUBLE_KARMA 3
#define SPECIAL_DAY_EXAMPLE 4

forward Action TTT_StartSpecialDay(int specailDay);
forward Action TTT_StopSpecialDay();
forward bool TTT_IsSpecialDayRunning(bool isRunning);

native bool TTT_IsSpecialDay();

public SharedPlugin __pl_special_days =
{
                name = "ttt_specialDays",
                file = "ttt_specialDays.smx",
#if defined REQUIRE_PLUGIN
                required = 1
#else
                required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_special_days_SetNTVOptional()
{
    MarkNativeAsOptional("TTT_StartSpecialDay");
    MarkNativeAsOptional("TTT_StopSpecialDay");
    MarkNativeAsOptional("TTT_IsSpecialDayRunning");
    MarkNativeAsOptional("TTT_IsSpecialDay");
}
#endif
