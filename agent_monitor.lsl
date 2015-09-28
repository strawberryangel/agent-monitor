key me;

integer CONTROL_CHANNEL = 8;
integer SCANNER_TIME_INTERVAL = 5;

string COMMAND_CLEAR_ARRIVALS = "clear arrivals";
string COMMAND_CLEAR_DEPARTURES = "clear departures";
string COMMAND_DUMP_DEPARTURES = "dump departures";
string COMMAND_DISABLE_ARRIVALS = "disable arrivals";
string COMMAND_ENABLE_ARRIVALS = "enable arrivals";
string COMMAND_HELP = "help";
string COMMAND_LIST = "list";
string COMMAND_STATUS = "status";

command_help() {
    llOwnerSay(COMMAND_CLEAR_ARRIVALS);
    llOwnerSay(COMMAND_CLEAR_DEPARTURES);
    llOwnerSay(COMMAND_DUMP_DEPARTURES + ": CSV dump of the departures table.");
    llOwnerSay(COMMAND_DISABLE_ARRIVALS);
    llOwnerSay(COMMAND_ENABLE_ARRIVALS);
    llOwnerSay(COMMAND_HELP);
    llOwnerSay(COMMAND_LIST);
    llOwnerSay(COMMAND_STATUS);
}

integer enable_arrivals = FALSE;

// First Seen timestamp
// First Seen ISO-8601
// Last Seen timestamp
// Last Seen ISO-8601
// UUID
// Login Name (This gets lost when they leave the region)
// Display Name (This gets lost when they leave the region)
integer STRIDE = 7;
integer OFFSET_FIRST_SEEN_TIMESTAMP = 0;
integer OFFSET_FIRST_SEEN_ISO = 1;
integer OFFSET_LAST_SEEN_TIMESTAMP = 2;
integer OFFSET_LAST_SEEN_ISO = 3;
integer OFFSET_ID = 4;
integer OFFSET_LOGIN_NAME = 5;
integer OFFSET_DISPLAY_NAME = 6;
list visitors;
list arrivals;
list departures;

clear_arrivals()
{
    arrivals = [];
}

clear_departures()
{
    departures = [];
}

command_disable_arrivals()
{
    enable_arrivals = FALSE;
    clear_arrivals();
    llOwnerSay("Arrivals disabled.");
}

command_dump_departures()
{
    llOwnerSay(">>>> list: " + llList2CSV(departures));
}

command_enable_arrivals()
{
    enable_arrivals = TRUE;
    clear_arrivals();
    llOwnerSay("Arrivals enabled.");
}

command_list()
{
    llOwnerSay(llGetTimestamp());
    llOwnerSay(" - - - - REGION - - - - ");

    llOwnerSay("CURRENT: " + (string)(llGetListLength(visitors)/STRIDE));
    display(visitors);
    if(enable_arrivals) {
        llOwnerSay("NEW: " + (string)(llGetListLength(arrivals)/STRIDE));
        display(arrivals);
        clear_arrivals();
    }
    llOwnerSay("DEPARTED: " + (string)(llGetListLength(departures)/STRIDE));
    display(departures);
}

command_status()
{
    llOwnerSay("Current Status:");
    if(enable_arrivals) llOwnerSay("Arrivals enabled."); else llOwnerSay("Arrivals disabled.");
}

display(list values)
{
    integer length = llGetListLength(values);
    if (length == 0) return;

    float currentTime = llGetGMTclock();
    string name;
    string duration;
    float delta;
    float last_seen;

    integer i=0;
    while(i < length)
    {
        last_seen = llList2Float(values, i + OFFSET_LAST_SEEN_TIMESTAMP);
        delta = last_seen - llList2Float(values, i + OFFSET_FIRST_SEEN_TIMESTAMP);
        duration = secondsToHMS(delta);
        name = llList2String(values, i + OFFSET_DISPLAY_NAME) + " (" + llList2String(values, i + OFFSET_LOGIN_NAME) + ")";
        llOwnerSay(duration + " " + name);
        i += STRIDE;
    }
}

do_it()
{
    region();

    // TODO: Clear departures
    // departures = [];
}

init()
{
    me = llGetOwner();
    llSetTimerEvent(SCANNER_TIME_INTERVAL);
    llListen(CONTROL_CHANNEL, "", NULL_KEY, "");
    llOwnerSay("Listening on channel " + (string)CONTROL_CHANNEL);
}

region()
{
    list avatarsInRegion = llGetAgentList(AGENT_LIST_REGION, []);
    integer numOfAvatars = llGetListLength(avatarsInRegion);

    // if no avatars, abort avatar listing process and give a short notice
    if (!numOfAvatars)
    {
        //        llOwnerSay("No avatars found within the region!");
        return;
    }

    // Update cycle
    float current_time = llGetGMTclock();
    integer index;

    while (index < numOfAvatars)
    {
        key id = llList2Key(avatarsInRegion, index);
        ++index;

        update(id, current_time);
    }

    remove_stale(current_time);
}

remove_stale(float current_time)
{
    integer count = llGetListLength(visitors);
    integer index = 0;
    float last_seen;
    while(index < count)
    {
        last_seen = llList2Float(visitors, index + OFFSET_LAST_SEEN_TIMESTAMP);
        if(last_seen < current_time)
        {
            // Remember this one.
            list departure = llList2List(visitors, index, index + STRIDE - 1);
            //llOwnerSay("removing: " + llList2CSV(departure));
            departures += departure;
            //llOwnerSay("list: " + llList2CSV(departures));

            // Excise this one from visitors list.
            list before = llList2List(visitors, 0, index-1);
            list after = llList2List(visitors, index + STRIDE, -1);
            if(index == 0)
                visitors = after;
            else if (index == count-STRIDE)
                visitors = before;
            else
                visitors = before + after;

            // Keep the index the same but reduce count.
            // The index now points to the next item.
            count -= STRIDE;
        }
        else
            index += STRIDE;
    }
}

replace_visitor_time(integer index, integer count, float value)
{
    list before = llList2List(visitors, 0, index + OFFSET_LAST_SEEN_TIMESTAMP - 1);
    list after = llList2List(visitors, index + OFFSET_LAST_SEEN_TIMESTAMP + 1, -1);
    visitors = before + [value] + after;
}

string secondsToHMS(float aSeconds)
{
    integer value = (integer)aSeconds;
    string hours = (string)(value / 3600);
    string minutes = (string)((value / 60) % 60);
    string seconds = (string)(value % 60);
    while(llStringLength(hours) < 3) hours = "0" + hours;
    while(llStringLength(minutes) < 2) minutes = "0" + minutes;
    while(llStringLength(seconds) < 2) seconds = "0" + seconds;
    return hours + ":" + minutes + ":" + seconds;
}

update(key visitor, float current_time)
{
    integer count = llGetListLength(visitors);
    integer index = 0;
    key id;
    while(index < count)
    {
        id = llList2Key(visitors, index + OFFSET_ID);
        if(id == visitor)
        {
            replace_visitor_time(index, count, current_time);
            return;
        }
        index += STRIDE;
    }

    list arrival = [current_time, llGetTimestamp(), current_time, llGetTimestamp(), visitor, llKey2Name(visitor), llGetDisplayName(visitor)];
    visitors += arrival;

    // Tracking arrivals is useful for debugging.
    if(enable_arrivals) arrivals += arrival;
}

default
{
    state_entry()
    {
        init();
    }
    listen(integer channel, string name, key id, string message)
    {
        if(message == COMMAND_LIST) command_list();
        else if(message == COMMAND_DISABLE_ARRIVALS) command_disable_arrivals();
        else if(message== COMMAND_ENABLE_ARRIVALS) command_enable_arrivals();
        else if(message== COMMAND_STATUS) command_status();
        else if(message== COMMAND_CLEAR_ARRIVALS) clear_arrivals();
        else if(message== COMMAND_CLEAR_DEPARTURES) clear_departures();
        else if(message== COMMAND_DUMP_DEPARTURES) command_dump_departures();
        else if(message == COMMAND_HELP) command_help();
    }
    timer()
    {
        do_it();
    }
}
