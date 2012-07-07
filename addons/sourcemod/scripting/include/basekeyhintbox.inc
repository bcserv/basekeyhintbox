#if defined __basekeyhintbox_included
#endinput
#endif
#define __basekeyhintbox_included

/*****************************************************************


P L U G I N   D E F I N E S


*****************************************************************/
#define MAX_KEYHINTBOX_LENGTH 256

/*****************************************************************


N A T I V E   D E F I N E S


*****************************************************************/

native BaseKeyHintBox_PrintToClientAll(Float:time, const String:format[], any:...);
native BaseKeyHintBox_PrintToClient(client, Float:time, const String:format[], any:...);
native Float:BaseKeyHintBox_GetPrintInterval();



/* DO NOT EDIT BELOW THIS LINE */

public SharedPlugin:__pl_basekeyhintbox = 
{
	name = "basekeyhintbox",
	file = "basekeyhintbox.smx",
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_basekeyhintbox_SetNTVOptional()
{
	MarkNativeAsOptional("BaseKeyHintBox_PrintToClientAll");
	MarkNativeAsOptional("BaseKeyHintBox_PrintToClient");
	MarkNativeAsOptional("BaseKeyHintBox_GetPrintInterval");
}
#endif
