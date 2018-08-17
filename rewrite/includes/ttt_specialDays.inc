#if defined _special_days_included
#endinput
#endif
#define _special_days_included

#define SPECIAL_DAY_COUNT 3
#define SPECIAL_DAY_BHOP 0
#define SPECIAL_DAY_TEST 1
#define SPECIAL_DAY_KOTH 2

forward Action TTT_StartSpecialDay(int specailDay);
forward Action TTT_StopSpecialDay();

public SharedPlugin __pl_special_days =
{
                name = "ttt_special_days",
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
}
#endif
