// Shared information
integer AGENT_MONITOR_CHANNEL = -38923;
integer MESSENGER_CHANNEL = -9892;
string COMMAND_DRL = "get departure request list";
string RESPONSE_DRL = "[drl]";
string DRL_SEPARATOR = "`";

integer DRL_OFFSET_FIRST_SEEN_ISO = 0;
integer DRL_OFFSET_LAST_SEEN_ISO = 1;
integer DRL_OFFSET_ID = 2;
integer DRL_OFFSET_LOGIN_NAME = 3;
integer DRL_OFFSET_DISPLAY_NAME = 4;


// Private information
float DEPARTURE_REQUEST_INTERVAL_MIN = 5.0;
float DEPARTURE_REQUEST_INTERVAL_MAX = 512.0;

float departure_request_interval;

init()
{
    reset_request_departures();
    llListen(MESSENGER_CHANNEL, "", NULL_KEY, "");
}

process_received_departures(string message)
{
    string line = llGetSubString(message, llStringLength(RESPONSE_DRL), -1);
    if(llStringLength(line) == 0)
    {
        slow_timer_down();
        llOwnerSay("Mail: No departures received. Slowed timer down. Current value = " + (string)departure_request_interval);
        return;
    }

    reset_request_departures();
}

reset_request_departures()
{
    departure_request_interval = DEPARTURE_REQUEST_INTERVAL_MIN;
    llSetTimerEvent(departure_request_interval);
}

request_departures()
{
    llOwnerSay("B: Requesting departures.");
    llMessageLinked(LINK_SET, AGENT_MONITOR_CHANNEL, COMMAND_DRL, NULL_KEY);
}

slow_timer_down()
{
    departure_request_interval = 2*departure_request_interval;
    if(departure_request_interval > DEPARTURE_REQUEST_INTERVAL_MAX) departure_request_interval = DEPARTURE_REQUEST_INTERVAL_MAX;
    llSetTimerEvent(departure_request_interval);
}

default
{
    link_message(integer sender_number, integer number, string message, key id)
    {
        return;
        llOwnerSay("Mail: received " + (string)number + " - " + message);
        if(number == MESSENGER_CHANNEL)
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
