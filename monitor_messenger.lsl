// Shared information
integer AGENT_MONITOR_CHANNEL = -38382938923;
integer MESSENGER_CHANNEL = -9892837432;
string COMMAND_DRL = "get departure request list";
string RESPONSE_DRL = "[drl]";
string DRL_SEPARATOR = "`";

integer DRL_OFFSET_FIRST_SEEN_ISO = 0;
integer DRL_OFFSET_LAST_SEEN_ISO = 1;
integer DRL_OFFSET_ID = 2;
integer DRL_OFFSET_LOGIN_NAME = 3;
integer DRL_OFFSET_DISPLAY_NAME = 4;

// Private information
integer DEPARTURE_REQUEST_INTERVAL_MIN = 2;
integer DEPARTURE_REQUEST_INTERVAL_MAX = 512;

integer departure_request_interval;

init()
{
    reset_request_departures();
    llListen(MESSENGER_CHANNEL, "", NULL_KEY, "");
}

process_received_departures(string message)
{
    string line = llGetSubString(message, llStringLength(RESPONSE_DRL), -1);
}

reset_request_departures()
{
    departure_request_interval = DEPARTURE_REQUEST_INTERVAL_MIN;
    llSetTimerEvent(departure_request_interval);
}

request_departures()
{
    llSay(AGENT_MONITOR_CHANNEL, COMMAND_DRL);
}

default
{
    listen(integer channel, string name, key id, string message)
    {
        if(channel == MESSENGER_CHANNEL)
        {
            if(llGetSubString(message, 0, llStringLength(RESPONSE_DRL)-1) == RESPONSE_DRL)
            {
                process_received_departures(message);
                return;
            }
        }
    }
    state_entry()
    {
        init();
    }
    timer()
    {
        request_departures();
    }

}
