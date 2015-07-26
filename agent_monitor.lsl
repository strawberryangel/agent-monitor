key me;

// First Seen timestamp
// First Seen ISO-8601
// Last Seen timestamp
// Last Seen ISO-8601
// UUID
integer STRIDE = 5;
integer OFFSET_FIRST_SEEN_TIMESTAMP = 0;
integer OFFSET_FIRST_SEEN_ISO = 1;
integer OFFSET_LAST_SEEN_TIMESTAMP = 2;
integer OFFSET_LAST_SEEN_ISO = 3;
integer OFFSET_ID = 4;
list visitors;

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

display(list values)
{
    integer length = llGetListLength(values);
    if (length == 0) return;

    float currentTime = llGetGMTclock();
    string name;
    key id;
    string duration;
    string from;

    integer i=0;
    while(i < length)
    {
        from = llList2String(values, i + OFFSET_FIRST_SEEN_ISO);
        float delta = currentTime - llList2Float(values, i + OFFSET_FIRST_SEEN_TIMESTAMP);
        duration = secondsToHMS(delta);
        id = llList2Key(values, i + OFFSET_ID);
        name = llGetDisplayName(id) + " (" + llKey2Name(id) + ")";
        llOwnerSay(duration + " " + name);
        i += STRIDE;
    }
}

init()
{
    me = llGetOwner();
}

float rand_omega()
{
    return llFrand(20.0) - 10.0;
}

rand_spin()
{
    llTargetOmega(<rand_omega(), rand_omega(), rand_omega()>, TWO_PI/(llFrand(30)+10), 1);
}

replace_visitor_time(integer index, integer count, float value)
{
    list before = llList2List(visitors, 0, index + OFFSET_LAST_SEEN_TIMESTAMP - 1);
    list after = llList2List(visitors, index + OFFSET_LAST_SEEN_TIMESTAMP + 1, -1);
    visitors = before + [value] + after;
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

    visitors += [current_time, llGetTimestamp(), current_time, llGetTimestamp(), visitor];
}

remove_visitor(integer index)
{
    if(index == 0)
        visitors = llList2List(visitors, STRIDE, -1);
    else
        visitors = llList2List(visitors, 0, index-1) + llList2List(visitors, index + STRIDE, -1);
}

remove_stale(float current_time)
{
    integer count = llGetListLength(visitors);
    integer index = 0;
    float last_seen;
    while(index < count)
    {
        last_seen = llList2Float(visitors, index+2);
        if(last_seen < current_time)
        {
            remove_visitor(index);
            return;
        }
        index += STRIDE;
    }
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
    display(visitors);
}

do_it()
{
    rand_spin();
    llOwnerSay(llGetTimestamp());
    llOwnerSay(" - - - - REGION - - - - ");
    region();
}

default
{
    state_entry()
    {
        init();
        llListen(7, "", NULL_KEY, "");
    }
    touch_end(integer total_number)
    {
        do_it();
    }
    listen(integer channel, string name, key id, string message)
    {
        do_it();
    }
}
