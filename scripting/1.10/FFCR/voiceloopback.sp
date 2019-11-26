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

/*public Query_VoiceLoopback_Callback(QueryCookie cookie, iClient, ConVarQueryResult hResult, const char[] cvarName, const char[] cvarValue)
{
	if (StringToInt(cvarValue) && !(GetClientListeningFlags(iClient) & VOICE_MUTED)) // loopback on and client not already muted
	{
		SetClientListeningFlags(iClient, VOICE_MUTED);
		PrintToChat(iClient, VOICE_LOOPBACK_MSG);
		LogMessage(LOG_MSG_LOOPBACK_MUTE, iClient);
	}
	
	return;
}*/

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
	
	if (FFCR_IsClientMuted(iClient))
	{
		if (!view_as<bool>(StringToInt(cCVarValue))) // Disabled // If we wouldent convert this to an Bool, Hackers could send a Value out of Range(0-1)
			FFCR_UnMute(iClient, false); // Unmute
	}
	
	else
		if (view_as<bool>(StringToInt(cCVarValue))) // Activated // If we wouldent convert this to an Bool, Hackers could send a Value out of Range(0-1)
			FFCR_UnMute(iClient, true); // Mute
}

/*
* Checks if an Client is muted by BaseComm or SourceComms.
*
* @param iClient	Client to Check for.
* @return 		True if the Client is allready muted, false if not.
*/
bool FFCR_IsClientMuted(int iClient)
{
	if (g_bBaseComm)
		return BaseComm_IsClientMuted(iClient);
		
	else if (g_bSourceComms)
		return (SourceComms_GetClientMuteType(iClient) != bNot);
		
	else
		return !!(GetClientListeningFlags(iClient) & VOICE_MUTED);
}

/*
* Mutes or Unmutes a specific Client, tries to use Basecomm or Sourcecomms before performing a simple Mute.
*
* @param iClient	Client to Mute.
* @param bAction	True to Mute, False to Unmute.
*/
void FFCR_UnMute(int iClient, bool bAction)
{
	if (g_bBaseComm)
		BaseComm_SetClientMute(iClient, bAction);
		
	else if (g_bSourceComms)
	{
		if (bAction)
		{
			char muteReason[64];
			Format(muteReason, sizeof(muteReason), "%t", "Mute Reason");
			SourceComms_SetClientMute(iClient, bAction, -1, true, muteReason); //-1 session mute, saved to DB
		}
		
		else
			SourceComms_SetClientMute(iClient, bAction);
	}
	
	else
		SetClientListeningFlags(iClient, bAction ? (GetClientListeningFlags(iClient) | VOICE_MUTED) : (GetClientListeningFlags(iClient) & ~VOICE_MUTED));
		
	if (bAction)
	{
		PrintToChat(iClient, "%t", VOICE_LOOPBACK_MSG);
		LogMessage(LOG_MSG_LOOPBACK_MUTE, iClient);
	}
	
	//else
	//	PrintToChat(iClient, "%t", ##); // TODO: Maybe later
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