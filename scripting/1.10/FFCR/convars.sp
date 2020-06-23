// Forlix FloodCheck
// http://forlix.org/, df@forlix.org
//
// Copyright (c) 2008-2013 Dominik Friedrichs

// convar defaults
#define EXCLUDE_CHAT_TRIGGERS   "1"
#define MUTE_VOICE_LOOPBACK     "1"

#define FLOOD_CHAT_INTERVAL     "4"
#define FLOOD_CHAT_NUM          "3"

#define FLOOD_HARD_INTERVAL     "2"
#define FLOOD_HARD_NUM          "200"
#define FLOOD_HARD_BAN_TIME     "150"

#define FLOOD_NAME_INTERVAL     "120"
#define FLOOD_NAME_NUM          "3"
#define FLOOD_NAME_BAN_TIME     "150"

#define FLOOD_CONNECT_INTERVAL  "5"
#define FLOOD_CONNECT_NUM       "2"
#define FLOOD_CONNECT_BAN_TIME  "50"


//- ConVars -//

SetupConVars()
{
	//- Misc -//
	CreateConVar("ffcr_version", PLUGIN_VERSION, "Forlix FloodCheck Redux Plugin Version", FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_UNLOGGED); // "notify" - So that we appear on Server Tracking Sites, "sponly" because we do not want Chat Messages about this CVar caused by "notify", "dontrecord" - So that we don't get saved to the Auto cfg, "unlogged" - Because changes of this CVar dosent need to be logged
	g_hCVar_ExcludeChatTriggers = CreateConVar("ffcr_exclude_chat_triggers", EXCLUDE_CHAT_TRIGGERS, "Excludes (1) or includes (0) SourceMod Chat Commands in the Chat Flood Detection", _, true, 0.0, true, 1.0);
	g_hCVar_MuteVoiceLoopback = CreateConVar("ffcr_mute_voice_loopback", MUTE_VOICE_LOOPBACK, "Mute players enabling 'voice_loopback' (0 = Disabled, 1 = Enabled)", _, true, 0.0, true, 1.0);
	//- Chat -//
	g_hCVar_ChatInterval = CreateConVar("ffcr_chat_interval", FLOOD_CHAT_INTERVAL, "Minimum average Interval in Seconds between a Players Chat- and Radio-Messages (0 = Disabled)", _, true, 0.0, true, 20.0);
	g_hCVar_ChatNum = CreateConVar("ffcr_chat_num", FLOOD_CHAT_NUM, "Player is considered spamming after undershooting <ffcr_chat_interval> this many Times", _, true, 1.0, true, 75.0);
	//- Hard Flood -//
	g_hCVar_HardInterval = CreateConVar("ffcr_hard_interval", FLOOD_HARD_INTERVAL, "Time in Seconds in which <ffcr_hard_num> Commands are allowed (0 = Disabled)", _, true, 0.0, true, 20.0);
	g_hCVar_HardNum = CreateConVar("ffcr_hard_num", FLOOD_HARD_NUM, "Maximum Number of Client Commands allowed in <ffcr_hard_interval> Seconds", _, true, 10.0, true, 750.0);
	g_hCVar_HardBanTime = CreateConVar("ffcr_hard_ban_time", FLOOD_HARD_BAN_TIME, "Number of Minutes a Client is banned for hard-flooding (0 = Forever)", _, true, 0.0, true, 20160.0);
	//- Namecheck -//
	g_hCVar_NameInterval = CreateConVar("ffcr_name_interval", FLOOD_NAME_INTERVAL, "Time in Seconds in which <ffcr_name_num> Name Changes are allowed (0 = Disable)", _, true, 0.0, true, 600.0);
	g_hCVar_NameNum = CreateConVar("ffcr_name_num", FLOOD_NAME_NUM, "Maximum Number of Name Changes allowed in <ffcr_name_interval> Seconds", _, true, 1.0, true, 20.0);
	g_hCVar_NameBanTime = CreateConVar("ffcr_name_ban_time", FLOOD_NAME_BAN_TIME, "Number of Minutes a Client is banned for Name-flooding (0 = Forever)", _, true, 0.0, true, 20160.0);
	//- Connect Check -//
	g_hCVar_ConnectInterval = CreateConVar("ffcr_connect_interval", FLOOD_CONNECT_INTERVAL, "Time in Seconds in which <ffcr_connect_num> Connects are allowed (0 = Disable)", _, true, 0.0, true, 60.0);
	g_hCVar_ConnectNum = CreateConVar("ffcr_connect_num", FLOOD_CONNECT_NUM, "Maximum Number of Connects allowed in <ffcr_connect_interval> Seconds", _, true, 1.0, true, 20.0);
	g_hCVar_ConnectBanTime = CreateConVar("ffcr_connect_ban_time", FLOOD_CONNECT_BAN_TIME, "Number of Seconds a Client is IP-banned for Connect-flooding", _, true, 2.0, true, 600.0);
	
	//- Misc -//
	HookConVarChange(g_hCVar_ExcludeChatTriggers, ConVarChanged_ExcludeChatTriggers);
	HookConVarChange(g_hCVar_MuteVoiceLoopback, ConVarChanged_MuteVoiceLoopback);
	//- Chat -//
	HookConVarChange(g_hCVar_ChatInterval, ConVarChanged_ChatInterval);
	HookConVarChange(g_hCVar_ChatNum, ConVarChanged_ChatNum);
	//- Hard Flood -//
	HookConVarChange(g_hCVar_HardInterval, ConVarChanged_HardInterval);
	HookConVarChange(g_hCVar_HardNum, ConVarChanged_HardNum);
	HookConVarChange(g_hCVar_HardBanTime, ConVarChanged_HardBanTime);
	//- Namecheck -//
	HookConVarChange(g_hCVar_NameInterval, ConVarChanged_NameInterval);
	HookConVarChange(g_hCVar_NameNum, ConVarChanged_NameNum);
	HookConVarChange(g_hCVar_NameBanTime, ConVarChanged_NameBanTime);
	//- Connect Check -//
	HookConVarChange(g_hCVar_ConnectInterval, ConVarChanged_ConnectInterval);
	HookConVarChange(g_hCVar_ConnectNum, ConVarChanged_ConnectNum);
	HookConVarChange(g_hCVar_ConnectBanTime, ConVarChanged_ConnectBanTime);
	
	AutoExecConfig(true, "Forlix_Floodcheck_Redux"); // We read the Values after the Hooks so we trigger an Readout // MyConVarChanged(INVALID_HANDLE, "0", "0"); // manually trigger convar readout
	
	return;
}


//- ConVar Hooks

//- Misc -//
public void ConVarChanged_ExcludeChatTriggers(Handle hConVar, const char[] cOldValue, const char[] cNewValue)
{
	g_bExcludeChatTriggers = GetConVarBool(hConVar);
}

public void ConVarChanged_MuteVoiceLoopback(Handle hConVar, const char[] cOldValue, const char[] cNewValue)
{
	g_bMuteVoiceLoopback = GetConVarBool(hConVar);
	Query_VoiceLoopback_All();
}

//- Chat -//
public void ConVarChanged_ChatInterval(Handle hConVar, const char[] cOldValue, const char[] cNewValue)
{
	g_fChatInterval = GetConVarFloat(hConVar);
}

public void ConVarChanged_ChatNum(Handle hConVar, const char[] cOldValue, const char[] cNewValue)
{
	g_iChatNum = GetConVarInt(hConVar);
}

//- Hard Flood -//
public void ConVarChanged_HardInterval(Handle hConVar, const char[] cOldValue, const char[] cNewValue)
{
	g_fHardInterval = GetConVarFloat(hConVar);
}

public void ConVarChanged_HardNum(Handle hConVar, const char[] cOldValue, const char[] cNewValue)
{
	g_iHardNum = GetConVarInt(hConVar);
}

public void ConVarChanged_HardBanTime(Handle hConVar, const char[] cOldValue, const char[] cNewValue)
{
	g_iHardBanTime = GetConVarInt(hConVar);
}

//- Namecheck -//
public void ConVarChanged_NameInterval(Handle hConVar, const char[] cOldValue, const char[] cNewValue)
{
	g_fNameInterval = GetConVarFloat(hConVar);
}

public void ConVarChanged_NameNum(Handle hConVar, const char[] cOldValue, const char[] cNewValue)
{
	g_iNameNum = GetConVarInt(hConVar);
}

public void ConVarChanged_NameBanTime(Handle hConVar, const char[] cOldValue, const char[] cNewValue)
{
	g_iNameBanTime = GetConVarInt(hConVar);
}

//- Connect Check -//
public void ConVarChanged_ConnectInterval(Handle hConVar, const char[] cOldValue, const char[] cNewValue)
{
	g_fConnectInterval = GetConVarFloat(hConVar);
}

public void ConVarChanged_ConnectNum(Handle hConVar, const char[] cOldValue, const char[] cNewValue)
{
	g_iConnectNum = GetConVarInt(hConVar);
}

public void ConVarChanged_ConnectBanTime(Handle hConVar, const char[] cOldValue, const char[] cNewValue)
{
	g_iConnectBanTime = GetConVarInt(hConVar);
} 