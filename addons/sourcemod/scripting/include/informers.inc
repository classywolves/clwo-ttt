#if defined _informers_included
    #endinput
#endif
#define _informers_included


native bool informers_IHaveAParent(int informer);
native bool informers_IAmEmpowered(int informer);
native int informers_GetMyParent(int informer);
native int informers_RemoveMyAdoption(int client);
native bool informers_SetMyParent(int informer, int parent, bool empower = false);
native int informers_RemoveMyParent(int informer);
native bool informers_CanAdopt(int informer, int client);
native bool informers_ForwardToMyParent(int informer, const char[] cCommand, const char[] cArgs, bool empowered = false, bool request = false);
native int informers_ShowAdoptions(int client);