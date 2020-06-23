// Forlix FloodCheck
// http://forlix.org/, df@forlix.org
//
// Copyright (c) 2008-2013 Dominik Friedrichs


void Query_VoiceLoopback(iClient) // Client is ingame and not a bot
{
	if (!g_bMuteVoiceLoopback)
		return;
		
	QueryClientConVar(iClient, "voice_loopback", Query_VoiceLoopback_Callback);
}

public void Query_VoiceLoopback_Callback(QueryCookie hCookie, int iClient, ConVarQueryResult hResult, const char[] cCVarName, const char[] cCVarValue)
{ // (Un)Mute the Client based on their current ConVar Value
	if (hResult != ConVarQuery_Okay) // Query is not okay :C
	{
		/*if(hResult == ConVarQuery_NotFound)
		{
			// TODO: Add report back System from KACR here
		}*/
		
		LogError("[Error] Client '%L' failed to Reply a Query, Reason: %s", iClient, hResult == ConVarQuery_NotFound ? "Not Found" : hResult == ConVarQuery_NotValid ? "Not Valid" : hResult == ConVarQuery_Protected ? "Protected" : "Is not Okay"); // The very last Case should NEVER happen
		return;
	}
	
	if (StringToInt(cCVarValue) != 0)  // Activated // If we wouldent convert this to an Bool, Hackers could send a Value out of Range(0-1)
		FFCR_UnMute(iClient, true); // Mute
		
	else // Disabled
		if (FFCR_IsClientMuted(iClient))
			FFCR_UnMute(iClient, false); // Unmute
}

/*
* Checks if an Client is muted by SourceComms, SB Material Admin or BaseComm.
*
* @param iClient	Client to Check for.
* @return 			True if the Client is allready muted, false if not.
*/
bool FFCR_IsClientMuted(int iClient)
{
	if (g_bSourceComms) // SourceComms
		return (SourceComms_GetClientMuteType(iClient) != bNot);
		
	else if (g_bSBMaterialAdmin) // SB Material Admin // This needs to run before BaseComm, because there is an SB Material Admin Plugins which registers as BaseComm
	{
		if (MAGetClientMuteType(iClient) && MAGetClientMuteType(iClient) != 2) // 0 - None, 1 - Voice Chat, 2 - Text Chat, 3 - Voice + Text Chat
			return true;
			
		else
			return false;
	}
	
	else if (g_bBaseComm) // BaseComm
		return BaseComm_IsClientMuted(iClient);
		
	else // Nothing installed? Lets perform a regular Check
		return !!(GetClientListeningFlags(iClient) & VOICE_MUTED);
}

/*
* Mutes or Unmutes a specific Client, tries to use Sourcecomms, SB Material Admin or Basecomm before performing a simple Mute.
*
* @param iClient	Client to Mute.
* @param bAction	True to Mute, False to Unmute.
*/
void FFCR_UnMute(int iClient, bool bAction)
{
	if (g_bSourceComms) // SourceComms
	{
		if (bAction)
		{
			//char muteReason[64]; TODO
			//Format(muteReason, sizeof(muteReason), "%t", "Mute Reason"); TODO
			if (!SourceComms_SetClientMute(iClient, bAction, -1, true, MSG_LOOPBACK_MUTE)) // -1 session mute, saved to DB
			{
				LogError("[Error] Failed to perform an SourceComms mute on '%L', he has been unmuted regularly instead", iClient);
				SetClientListeningFlags(iClient, GetClientListeningFlags(iClient) | VOICE_MUTED);
			}
		}
		
		else
			if (!SourceComms_SetClientMute(iClient, bAction))
			{
				LogError("[Error] Failed to perform an SourceComms unmute on '%L', he has been unmuted regularly instead", iClient);
				SetClientListeningFlags(iClient, GetClientListeningFlags(iClient) & ~VOICE_MUTED);
			}
	}
	
	else if (g_bSBMaterialAdmin) // SB Material Admin // This needs to run before BaseComm, because there is an SB Material Admin Plugins which registers as BaseComm
	{
		char cSteamID[16], cName[32], cIP[MAX_IPPORT_LEN];
		int iTimeLeft;
		GetClientAuthId(iClient, AuthId_Steam3, cSteamID, 16);
		GetClientIP(iClient, cIP, MAX_IPPORT_LEN); // No Port
		GetClientName(iClient, cName, 32);
		if (!GetMapTimeLeft(iTimeLeft))
			iTimeLeft = 60; // Operation not supported? Lets set the Mute Time to 60 Mins
			
		if (iTimeLeft <= 0)
			iTimeLeft = 60; // Infinite Map Time? Lets set the Mute Time to 60 Mins
			
		if (!MAOffSetClientMuteType(0, cSteamID, cIP, cName, MSG_LOOPBACK_MUTE, bAction ? MA_MUTE : MA_UNMUTE, iTimeLeft > 360 ? 60 : iTimeLeft)) // More than 6 Hours? The Map Creator probably done sh*t
		{
			LogError("[Error] Failed to perform an SB Material Admin %s on '%L', he has been %s regularly instead", bAction ? "mute" : "unmute", iClient, bAction ? "muted" : "unmuted")
			MALog(MA_LogAction, "[Error] Failed to perform an SB Material Admin %s on '%L', he has been %s regularly instead", bAction ? "mute" : "unmute", iClient, bAction ? "muted" : "unmuted");
			SetClientListeningFlags(iClient, GetClientListeningFlags(iClient) & ~VOICE_MUTED);
		}
	}
	
	else if (g_bBaseComm) // BaseComm
	{
		if (!BaseComm_SetClientMute(iClient, bAction))
		{
			LogError("[Error] Failed to perform an BaseComm %s on '%L', he has been %s regularly instead", bAction ? "mute" : "unmute", iClient, bAction ? "muted" : "unmuted");
			SetClientListeningFlags(iClient, bAction ? (GetClientListeningFlags(iClient) | VOICE_MUTED) : (GetClientListeningFlags(iClient) & ~VOICE_MUTED));
		}
	}
	
	else // Nothing installed? Lets perform a regular Mute
		SetClientListeningFlags(iClient, bAction ? (GetClientListeningFlags(iClient) | VOICE_MUTED) : (GetClientListeningFlags(iClient) & ~VOICE_MUTED));
		
	if (bAction)
	{
		PrintToChat(iClient, VOICE_LOOPBACK_MSG);
		LogMessage("[Info][FFCR] Client '%L' had a Voice Loopback running, he has been muted for now", iClient);
	}
	
	//else
	//	PrintToChat(iClient, "%s" + VOICE_LOOPBACK_MSG, ##); // TODO: Maybe later
}

/*
* Triggers an Voice Loopback Check for all Ingame Clients
*/
Query_VoiceLoopback_All()
{
	if (!g_bMuteVoiceLoopback)
		return;
		
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		if(IsClientInGame(iClient) && !IsFakeClient(iClient))
			QueryClientConVar(iClient, "voice_loopback", Query_VoiceLoopback_Callback);
			
	return;
}