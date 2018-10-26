// Forlix FloodCheck
// http://forlix.org/, df@forlix.org
//
// Copyright (c) 2008-2013 Dominik Friedrichs

bool FriendlyTime(time_s, char[] str_ftime, str_ftime_len, bool compact = true)
{
	char days_pf[16], hrs_pf[16], mins_pf[16], secs_pf[16];
	
	if(compact)
	{
		days_pf = "d";
		hrs_pf = "h";
		mins_pf = "m";
		secs_pf = "s";
	}
	
	else
	{
		days_pf = " days";
		hrs_pf = " hours";
		mins_pf = " minutes";
		secs_pf = " seconds";
	}
	
	if(time_s < 0)
	{
		str_ftime[0] = '\0';
		return false;
	}
	
	int days = time_s / 86400;
	int hrs = (time_s / 3600) % 24;
	int mins = (time_s / 60) % 60;
	int secs = time_s % 60;
	
	if(time_s < 60)
		Format(str_ftime, str_ftime_len, "%u%s", secs, secs_pf);
	
	else if(time_s < 3600)
		Format(str_ftime, str_ftime_len, "%u%s %u%s", mins, mins_pf, secs, secs_pf);
	
	else if(time_s < 86400)
		Format(str_ftime, str_ftime_len, "%u%s %u%s", hrs, hrs_pf, mins, mins_pf);
	
	else
		Format(str_ftime, str_ftime_len, "%u%s %u%s", days, days_pf, hrs, hrs_pf);
	
	return true;
}

bool IsClientNameAllowed(client)
{
	char name[MAX_NAME_LEN];
	name[0] = '\0';
	
	GetClientName(client, name, sizeof(name));
	int len = strlen(name);
	
	if(name[0] == '&' && len >= 2 && name[len - 1] == '&') // those &names& cause clientside glitches
		return false;
		
	if(FindCharInString(name, '%') >= 0) // also disallow any % just in case
		return false;
		
	// finally test against general string restrictions
	return !MakeStringPrintable(name, sizeof(name), "");
}

bool MakeStringPrintable(char[] str, str_len_max, const char[] empty)
{
	// replaces sequences of \n and \t with space if
	// surrounded by non-space printable characters.
	// removes all other control characters, and if
	// the resulting string has zero-length or contains
	// only spaces, replaces it with the empty-string.
	
	int r = 0, w = 0;
	
	bool modified = false;
	
	bool nonspace = false;
	bool addspace = false;
	
	if(str[0])
	{
		do
		{
			if(str[r] < '\x20')
			{
				modified = true;
				
				if((str[r] == '\n' || str[r] == '\t') && w > 0 && str[w - 1] != '\x20')
					addspace = true;
			}
			
			else
			{
				if(str[r] != '\x20')
				{
					nonspace = true;
					
					if(addspace)
						str[w++] = '\x20';
				}
				
				addspace = false;
				str[w++] = str[r];
			}
		}
		
		while(str[++r])
		{
			str[w] = '\0';
		}
	}
	
	if(!nonspace)
	{
		modified = true;
		strcopy(str, str_len_max, empty);
	}
	
	return modified;
}

bool TruncateString(char[] str, str_len, truncate_to)
{
	if(str_len <= truncate_to)
		return false;
		
	if(truncate_to < 3)
		truncate_to = 3;
		
	str[truncate_to - 3] = '.';
	str[truncate_to - 2] = '.';
	str[truncate_to - 1] = '.';
	str[truncate_to] = '\0';
	
	return true;
}