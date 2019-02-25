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
	MarkNativeAsOptional("Skills_SetPoints");
    MarkNativeAsOptional("Skills_GetLevel");
	MarkNativeAsOptional("Skills_SetLevel");
    MarkNativeAsOptional("Skills_GetExperience");
	MarkNativeAsOptional("Skills_SetExperience");
}
#endif

#define Skill_Health 1
#define Skill_Invisibility 2
#define Skill_ReducedFallDamage 6
#define Skill_Speed 7
#define Skill_Binoculars 8
#define Skill_NightVision 9
#define Skill_Flash 11
#define Skill_Scavenger 12
#define Skill_Vampire 18
#define Skill_Necrophilia 21

native int Skills_GetPoints(int client, int upgrade);
native void Skills_SetPoints(int client, int upgrade, int points);

native int Skills_GetLevel(int client);
native void Skills_SetLevel(int client, int level);
native int Skills_GetExperience(int client);
native void Skills_SetExperience(int client, int experience);

public int Skills_Limit(int value, int min, int max) {
	if (value < min) return min;
	if (value > max) return max;
	return value;
}
