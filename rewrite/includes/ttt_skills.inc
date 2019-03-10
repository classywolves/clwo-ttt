#if defined _ttt_skills_included
	#endinput
#endif
#define _ttt_skills_included

public SharedPlugin __pl_ttt_upgrades =
{
	name = "ttt_skills",
	file = "ttt_skills.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_ttt_upgrades_SetNTVOptional()
{
	MarkNativeAsOptional("Skills_GetPoints");
    MarkNativeAsOptional("Skills_GetLevel");
    MarkNativeAsOptional("Skills_GetExperience");
	MarkNativeAsOptional("Skills_AddExperience");
}
#endif

#define Skill_Health                1
#define Skill_Invisibility          2
#define Skill_ReducedFallDamage     3
#define Skill_Speed                 4
#define Skill_Binoculars            5
#define Skill_NightVision           6
#define Skill_Flash                 7
#define Skill_Scavenger             8
#define Skill_Vampire               9
#define Skill_Necrophilia           10

native void Skills_RegisterSkill(int skill, char[] name, char[] description, int max);

native int Skills_GetPoints(int client, int skill);
native int Skills_GetLevel(int client);
native int Skills_GetExperience(int client);
native void Skills_AddExperience(int client, int experience);

stock int Skills_GetSkill(int client, int skill, int min, int max)
{
    int rank = Skills_GetPoints(client, skill);
    if (rank < min)
    {
        rank = min;
    }
    if (rank > max)
    {
        rank = max;
    }

    return rank;
}

stock int Skills_Limit(int value, int min, int max)
{
	if (value < min) return min;
	if (value > max) return max;
	return value;
}
