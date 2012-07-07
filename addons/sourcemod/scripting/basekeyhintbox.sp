/*****************************************************************

    Base Key Hint Box
	Copyright (C) 2011 BCServ (plugins@bcserv.eu)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
*****************************************************************/

/*****************************************************************


C O M P I L E   O P T I O N S


*****************************************************************/
// enforce semicolons after each code statement
#pragma semicolon 1

/*****************************************************************


P L U G I N   I N C L U D E S


*****************************************************************/
#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <smlib/pluginmanager>
#include <basekeyhintbox>
#include <config>

/*****************************************************************


P L U G I N   I N F O


*****************************************************************/
public Plugin:myinfo = {
	name 						= "Base Key Hint Box",
	author 						= "BCServ",
	description 				= "Provides native functions for the 'KeyHintBox' so that multiple plugins can access it without overwriting eachother",
	version 					= "1.0",
	url 						= "http://bcserv.eu/"
}

/*****************************************************************


		P L U G I N   D E F I N E S


*****************************************************************/
#define PRINT_INTERVAL 0.5

#define MAX_PLUGINS 30

#define CONFIG_PATH "configs/basekeyhintbox.conf"

/*****************************************************************


		G L O B A L   V A R S


*****************************************************************/
// Console Variables
new Handle:g_cvarEnable 					= INVALID_HANDLE;
new Handle:g_cvarMaxLines = INVALID_HANDLE;

// Console Variables: Runtime Optimizers
new g_iPlugin_Enable 					= 1;
new g_iPlugin_MaxLines = 20;

// Plugin Internal Variables


// Config
new Handle:g_hConfig = INVALID_HANDLE;
new String:g_hConfig_BuiltPath[PLATFORM_MAX_PATH];
new String:g_szConfig_Plugin_FileName[MAX_PLUGINS][PLATFORM_MAX_PATH];
new Handle:g_hConfig_Plugin_Handle[MAX_PLUGINS];
new g_iConfig_Plugin_CurrentId = 0;

// Library Load Checks


// Game Variables


// Server Variables


// Map Variables


// Client Variables
new String:g_szMessage_Content[MAX_PLUGINS][MAXPLAYERS+1][MAX_KEYHINTBOX_LENGTH];
new Float:g_flMessage_Time[MAX_PLUGINS][MAXPLAYERS+1];

// M i s c


/*****************************************************************


		F O R W A R D   P U B L I C S


*****************************************************************/
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max){
	
	//reg me as lib
	RegPluginLibrary("basekeyhintbox");
	
	CreateNative("BaseKeyHintBox_PrintToClientAll",NF_BaseKeyHintBox_PrintToClientAll);
	CreateNative("BaseKeyHintBox_PrintToClient",NF_BaseKeyHintBox_PrintToClient);
	CreateNative("BaseKeyHintBox_GetPrintInterval",NF_BaseKeyHintBox_GetPrintInterval);
	return APLRes_Success;
}

public OnPluginStart() {
	
	// Initialization for SMLib
	PluginManager_Initialize("basekeyhintbox","[SM] ");
	
	// Translations
	// LoadTranslations("common.phrases");
	
	
	// Command Hooks (AddCommandListener) (If the command already exists, like the command kill, then hook it!)
	
	
	// Register New Commands (PluginManager_RegConsoleCmd) (If the command doesn't exist, hook it here)
	
	
	// Register Admin Commands (PluginManager_RegAdminCmd)
	
	
	// Cvars: Create a global handle variable.
	g_cvarEnable = PluginManager_CreateConVar("enable","1","Enables or disables this plugin");
	g_cvarMaxLines = PluginManager_CreateConVar("maxlines","20","this value fixes the keyhintbox to be always 20 lines high",FCVAR_PLUGIN,true,0.0);
	
	// Hook ConVar Change
	HookConVarChange(g_cvarEnable,ConVarChange_Enable);
	HookConVarChange(g_cvarMaxLines,ConVarChange_MaxLines);
	
	// Event Hooks
	
	
	// Library
	
	
	/* Features
	if(CanTestFeatures()){
		
	}
	*/
	
	// Create ADT Arrays
	
	
	// Timers
	CreateTimer(PRINT_INTERVAL, Timer_PrintToKeyHintBox, INVALID_HANDLE, TIMER_REPEAT);
	
}

public OnMapStart() {
	
	// hax against valvefail (thx psychonic for fix)
	if (GuessSDKVersion() == SOURCE_SDK_EPISODE2VALVE) {
		SetConVarString(Plugin_VersionCvar, Plugin_Version);
	}
	
	//check for config extension
	if(GetExtensionFileStatus("config.ext") != 1){
		SetFailState("Extension 'config.ext' isn't loaded! Get it from here: https://forums.alliedmods.net/showthread.php?t=69167 if you got already the extension then ask for help in the sourcemod forum!");
	}
	
	//load config
	BuildPath(Path_SM, g_hConfig_BuiltPath, sizeof(g_hConfig_BuiltPath), CONFIG_PATH);
	if(FileExists(g_hConfig_BuiltPath)){
		GetConfig();
	}
	else {
		WriteConfig();
	}
}


public OnMapEnd(){
	
	CloseHandle(g_hConfig);
	g_hConfig = INVALID_HANDLE;
}

public OnConfigsExecuted(){
	
	// Set your ConVar runtime optimizers here
	g_iPlugin_Enable = GetConVarInt(g_cvarEnable);
	g_iPlugin_MaxLines = GetConVarInt(g_cvarMaxLines);
	
	//Mind: this is only here for late load, since on map change or server start, there isn't any client.
	//Remove it if you don't need it.
	Client_InitializeAll();
}

public OnClientConnected(client){
	
	Client_Initialize(client);
}

public OnClientPostAdminCheck(client){
	
	Client_Initialize(client);
}


/**************************************************************************************


	C A L L B A C K   F U N C T I O N S


**************************************************************************************/
public Action:Timer_PrintToKeyHintBox(Handle:timer){
	
	PrintKeyHintBoxToClientAll();
	return Plugin_Continue;
}

/**************************************************************************************

	N A T I V E   F U N C T I O N S

**************************************************************************************/
public NF_BaseKeyHintBox_PrintToClientAll(Handle:plugin, numParams){
	
	new id = GetPluginId(plugin);
	if(id == -1){
		ThrowNativeError(SP_ERROR_NATIVE,"GetPluginId has failed and returned -1");
		return;
	}
	
	decl String:message[MAX_KEYHINTBOX_LENGTH];
	LOOP_CLIENTS(client,CLIENTFILTER_INGAME){
		
		new Float:timeout = GetNativeCell(1);
		g_flMessage_Time[id][client] = (timeout < 0.0) ? -1.0 : (GetGameTime() + timeout);
		
		SetGlobalTransTarget(client);
		FormatNativeString(0,2,3,sizeof(message),_,message);
		strcopy(g_szMessage_Content[id][client],sizeof(g_szMessage_Content[][]),message);
	}
}

public NF_BaseKeyHintBox_PrintToClient(Handle:plugin, numParams){
	
	new id = GetPluginId(plugin);
	if(id == -1){
		ThrowNativeError(SP_ERROR_NATIVE,"GetPluginId has failed and returned -1");
		return;
	}
	
	new client = GetNativeCell(1);
	if(!Client_IsValid(client)){
		ThrowNativeError(SP_ERROR_NATIVE,"client index %d is invalid or client is not in game",client);
		return;
	}
	
	new Float:timeout = GetNativeCell(2);
	g_flMessage_Time[id][client] = (timeout < 0.0) ? -1.0 : (GetGameTime() + timeout);
	
	decl String:message[MAX_KEYHINTBOX_LENGTH];
	SetGlobalTransTarget(client);
	FormatNativeString(0,3,4,sizeof(message),_,message);
	
	strcopy(g_szMessage_Content[id][client],sizeof(g_szMessage_Content[][]),message);
}

public NF_BaseKeyHintBox_GetPrintInterval(Handle:plugin, numParams){
	
	return _:PRINT_INTERVAL;
}
/**************************************************************************************

	C O N  V A R  C H A N G E

**************************************************************************************/
/* Example Callback Con Var Change*/
public ConVarChange_Enable(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_iPlugin_Enable = StringToInt(newVal);
}

public ConVarChange_MaxLines(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	g_iPlugin_MaxLines = StringToInt(newVal);
}

/**************************************************************************************

	C O M M A N D S

**************************************************************************************/
/* Example Command Callback
public Action:Command_(client, args)
{
	
	return Plugin_Handled;
}
*/


/**************************************************************************************

	E V E N T S

**************************************************************************************/
/* Example Callback Event
public Action:Event_Example(Handle:event, const String:name[], bool:dontBroadcast)
{

}
*/


/***************************************************************************************


	P L U G I N   F U N C T I O N S


***************************************************************************************/
GetConfig(){
	
	if(g_hConfig != INVALID_HANDLE){
		CloseHandle(g_hConfig);
	}
	g_hConfig = ConfigCreate();
	
	new line;
	new String:errorMsg[PLATFORM_MAX_PATH];
	if (!ConfigReadFile(g_hConfig, g_hConfig_BuiltPath, errorMsg, sizeof(errorMsg), line)) {
		SetFailState("Can't read file %s: Error: \"%s\" @ line %d", g_hConfig_BuiltPath, errorMsg, line);
	}
	
	new Handle:hPriorityList = ConfigLookup(g_hConfig, "keyhintbox_priority");
	if(hPriorityList == INVALID_HANDLE){
		LogError("can't load plugins from file, it appears to be empty");
		return;
	}
	
	g_iConfig_Plugin_CurrentId = 0;
	
	new length = ConfigSettingLength(hPriorityList);
	for (new i=0; i<length; i++) {
		
		ConfigSettingGetStringElement(hPriorityList,i,g_szConfig_Plugin_FileName[g_iConfig_Plugin_CurrentId],sizeof(g_szConfig_Plugin_FileName[]));
		g_hConfig_Plugin_Handle[g_iConfig_Plugin_CurrentId] = FindPluginByFile(g_szConfig_Plugin_FileName[g_iConfig_Plugin_CurrentId]);
		g_iConfig_Plugin_CurrentId++;
		
		if(g_iConfig_Plugin_CurrentId >= MAX_PLUGINS){
			
			LogError("can't track more than %d plugins",MAX_PLUGINS);
			break;
		}
	}
}

WriteConfig(){
	
	if(g_hConfig != INVALID_HANDLE){
		CloseHandle(g_hConfig);
	}
	g_hConfig = ConfigCreate();
	
	new Handle:hPriorityList = ConfigSettingAdd(ConfigRootSetting(g_hConfig),"keyhintbox_priority",ST_List);
	
	for(new i=0;i<sizeof(g_szConfig_Plugin_FileName);i++){
		
		if(g_szConfig_Plugin_FileName[i][0] == '\0'){
			continue;
		}
		
		new Handle:hFileName = ConfigSettingAdd(hPriorityList,"test",ST_String);
		ConfigSettingSetString(hFileName,g_szConfig_Plugin_FileName[i]);
	}
	
	ConfigWriteFile(g_hConfig,g_hConfig_BuiltPath);
}

/***************************************************************************************

	S T O C K

***************************************************************************************/
stock GetPluginId(Handle:plugin){
	
	for(new i=0;i<MAX_PLUGINS;i++){
		
		if(plugin == g_hConfig_Plugin_Handle[i]){
			
			return i;
		}
	}
	
	for(new i=0;i<MAX_PLUGINS;i++){
		
		if(plugin == FindPluginByFile(g_szConfig_Plugin_FileName[i])){
			
			g_hConfig_Plugin_Handle[i] = plugin;
			return i;
		}
	}
	
	GetConfig();
	
	for(new i=0;i<MAX_PLUGINS;i++){
		
		if(plugin == g_hConfig_Plugin_Handle[i]){
			
			return i;
		}
	}
	
	GetPluginFilename(plugin,g_szConfig_Plugin_FileName[g_iConfig_Plugin_CurrentId],sizeof(g_szConfig_Plugin_FileName[]));
	g_hConfig_Plugin_Handle[g_iConfig_Plugin_CurrentId] = plugin;
	g_iConfig_Plugin_CurrentId++;
	
	WriteConfig();
	
	return g_iConfig_Plugin_CurrentId;
}

stock PrintKeyHintBoxToClientAll(){
	
	if(g_iPlugin_Enable == 0){
		return;
	}
	
	LOOP_CLIENTS(client,CLIENTFILTER_INGAMEAUTH){
		
		PrintKeyHintBoxToClient(client);
	}
}

stock PrintKeyHintBoxToClient(client){
	
	if(g_iPlugin_Enable == 0){
		return;
	}
	
	if(Client_GetButtons(client) & IN_SCORE){
		//Client_PrintKeyHintText(client,"");
		return;
	}
	
	new String:message[MAX_KEYHINTBOX_LENGTH];
	new Float:theGameTime = GetGameTime();
	
	for(new pluginId=0;pluginId<MAX_PLUGINS;pluginId++){
		
		if(g_szMessage_Content[pluginId][client][0] != '\0'){
			
			if(g_flMessage_Time[pluginId][client] != -1.0 && g_flMessage_Time[pluginId][client]+0.1 < theGameTime){
				
				g_szMessage_Content[pluginId][client][0] = '\0';
			}
			else {
				
				Format(message,sizeof(message),"%s%s\n",message,g_szMessage_Content[pluginId][client]);
			}
		}
	}
	
	/* fixed to height/lines */
	new lines = String_CountChar(message,'\n');
	for(new i=lines;i<=g_iPlugin_MaxLines;i++){
		Format(message,sizeof(message),"%s\n",message);
	}
	
	//PrintToConsole(client,message);
	Client_PrintKeyHintText(client,message);
}

stock String_CountChar(const String:searchString[], char){
	
	new count = 0;
	new size=strlen(searchString);
	
	for(new i=0;i<size;i++){
		
		if(searchString[i] == char){
			
			count++;
		}
	}
	
	return count;
}


stock Client_InitializeAll(){
	
	for(new client=1;client<=MaxClients;client++){
		
		if(!IsClientInGame(client)){
			continue;
		}
		
		Client_Initialize(client);
	}
}

stock Client_Initialize(client){
	
	//Variables
	Client_InitializeVariables(client);
	
	
	//Functions
	
	
	//Functions where the player needs to be in game
	if(!IsClientInGame(client)){
		return;
	}
}

stock Client_InitializeVariables(client){
	
	//Plugin Client Vars
	for(new i=0;i<MAX_PLUGINS;i++){
		g_szMessage_Content[i][client][0] = '\0';
	}
}

