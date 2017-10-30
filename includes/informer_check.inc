#include <imod>

/* User Type */
#define USER_TYPE_COMMAND      0
#define USER_TYPE_IS_STAFF     1
#define USER_TYPE_BROADCAST    2
#define USER_TYPE_GROUPNAME    3
#define USER_TYPE_FULLNAME     4
#define USER_TYPE_SCORENAME    5
#define USER_TYPE_CHATNAME     6
#define USER_TYPE_MULTI_TARGET 7

stock bool should_informer_block(int client) {
	char name[200];
	iMod_GetUserTypeString(iMod_GetUserType(client), USER_TYPE_FULLNAME, name, sizeof(name));
	if (!StrEqual(name, "Informer")) return false;
	if (!Count_Staff(false)) return false;
	return true;
}