/** Double-include prevention */
#if defined _dataretriever2_included_
  #endinput
#endif
#define _dataretriever2_included_


public SharedPlugin __pl_dataretriever2 = 
{
	name = "inilo-dataretriever2",
	file = "inilo-dataretriever2.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};


#define DC2_STATE_REBEL									(1 << 1)	
#define DC2_STATE_WARDEN								(1 << 2)
#define DC2_STATE_FD									(1 << 3)


#if !defined REQUIRE_PLUGIN
public __pl_dataretriever2_SetNTVOptional()
{
	MarkNativeAsOptional("DR2_GetRandomLocation");
	MarkNativeAsOptional("DR2_GetRandomLocationFromTimeBlock");
	MarkNativeAsOptional("DR2_GetRandomLocationSpreadOut");
	MarkNativeAsOptional("DR2_LocationSpreadOutCount");
}
#endif

native bool DR2_GetRandomLocation(float loc[3]);
native bool DR2_GetRandomLocationFromTimeBlock(float loc[3], int TimeBlock);
native bool DR2_GetRandomLocationSpreadOut(float loc[3]);
native int DR2_LocationSpreadOutCount();

stock void GetDataRetrieverState(int state, char[] output, int maxlen)
{
	if(state & DC2_STATE_REBEL)
	{
		Format(output, maxlen, "%s%s", output, "DC2_STATE_REBEL");
	}
	if(state & DC2_STATE_WARDEN)
	{
		Format(output, maxlen, "%s%s", output, "DC2_STATE_REBEL");
	}
	if(state & DC2_STATE_FD)
	{
		Format(output, maxlen, "%s%s", output, "DC2_STATE_REBEL");
	}
}


