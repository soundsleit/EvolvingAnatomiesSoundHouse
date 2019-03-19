// ********************************** //
// house_clock
// for Dyscorpia: Evolving Anatomies Sound House
// Dec. 2018 - Feb. 2019 by (cc) Scott Smallwood

// stupid MOTU offset
2=>int offset;
//the initial volume
.05=>float initVolume;



15=>int bellMaxVoices;
8=>int potMaxVoices;
4=> int audioChannels;

//audio patch setup

//create bell soundbuffers (double - in case of overlap)
SndBuf bell[bellMaxVoices*2];
//create pot soundbuffers
SndBuf pot[potMaxVoices];
//ambientMinute buffers
SndBuf s1;
SndBuf s2;
Gain g[audioChannels];
 
//set initial gains
for (0=>int i; i<audioChannels; i++)
    initVolume  => g[i].gain;
 
.02 => s1.gain;
.03 => s2.gain;
0=>s2.rate;
0=>s1.rate;
    
"snd/ambiences/bellambience_0alt.wav" => s1.read;
"snd/ambiences/bellambience_1alt.wav" => s2.read;

s1.chan(0) => g[0] => dac.chan(offset);
s1.chan(0) => g[1] => dac.chan(offset+1);
s2.chan(0) => g[2] => dac.chan(offset+2);
s2.chan(0) => g[3] => dac.chan(offset+3);



//hook up and spatialize bells
for (0=>int i; i<bellMaxVoices; i++)
{
    (i%audioChannels) + offset => int _channel;
    bell[i].chan(0)=>g[_channel - offset]=>dac.chan(_channel);
    .1 => bell[i].gain;
    0 => bell[i].rate;
}

//hook up and spatialize pots
for (0=>int i; i<potMaxVoices; i++)
{
    (i%audioChannels) + offset => int _channel;
    pot[i].chan(0)=>g[_channel - offset]=>dac.chan(_channel);
    .5 => pot[i].gain;
    0 => pot[i].rate;
}


//trigger the pot sequence every seconds
spork ~ PotsSequenceTrigger(20);

//trigger the chimes every 10 seconds (don't go shorter!)
spork ~ ChimesSequenceTrigger(10);

//ambiences on the minute
spork ~ AmbTrigger(150);

1::week =>now;

//end

fun void AmbTrigger(int _interval)
{
    while (true)
    {
        spork ~ MinuteAmbiences(_interval);
        _interval::second => now;
    }
    
}

fun void PotsSequenceTrigger(int _interval)
{
    while (true)
    {
        spork ~ PotsSequence(4,Math.random2(80,200));
        _interval::second => now;
    }
    
}

fun void ChimesSequenceTrigger(int _interval)
{
    0=>int inc;
    while (true)
    {
        spork ~ ChimesSequence(Math.random2(1,15),Math.random2(50,1000),inc%2);
        _interval::second => now;
    }
    
}


// **** **** **** **** **** **** **** ****
//ChimesSequence
//Creates a chime at regular intervals for a set amount of repetitions, setable timing and
//other things
fun void ChimesSequence(int _chimes, int _timeChunk, int _groupOffset)
{
    19 => int maxBellSounds;
    1 => int random;
    
    if (_groupOffset == 1) bell.cap()/2=>_groupOffset;
    
    //setup files (randomized or in order)
    if (!random)
    {
        
        for (0=>int i; i<_chimes; i++)
        {
            "snd/bells-single/bell_" + i + ".wav" =>bell[i+_groupOffset].read;
        }
    }
    
    if (random)
    {
        
        for (0=>int i; i<_chimes; i++)
        {
            "snd/bells-single/bell_" + Math.random2(0,maxBellSounds-1) + ".wav" => bell[i+_groupOffset].read;
        }
    }
    
    for (0=>int i; i<_chimes; i++)
    {
        0=>bell[(i%bellMaxVoices)+_groupOffset].rate;
    }
    
    //step through the bell sequence
    for (0=>int i; i<_chimes; i++)
    {
        //make sure that i wraps around if it's bigger than the max
        0=>bell[(i%bellMaxVoices)+_groupOffset].pos;
        1=>bell[(i%bellMaxVoices)+_groupOffset].rate;
        _timeChunk::ms => now;
    }
    
    
    12::second => now;
}

// **** **** **** **** **** **** **** ****
//PotsSequence
//Creates a chime at regular intervals for a set amount of repetitions, setable timing and
//other things

fun void PotsSequence(int _chimes, int _timeChunk)
{
    
    8 => int MaxPotSounds;
    
    for (0=>int i; i<_chimes; i++)
    {
        "snd/pots-single/pot_" + i + ".wav" =>pot[i].read;
    }
    for (0=>int i; i<_chimes; i++)
    {
        0=>pot[i%potMaxVoices].rate;
    }
    
    //step through the pot sequence
    for (0=>int i; i<_chimes; i++)
    {
        //make sure the voices wrap around if larger than max
        0=>pot[i%potMaxVoices].pos;
        1=>pot[i%potMaxVoices].rate;
        _timeChunk::ms => now;
    }
    
    
    12::second => now;
}


fun void MinuteAmbiences(int _interval)
{

     .3 => s1.gain;
     .3 => s2.gain;

    //play start ambience
    .9=>s2.rate;
    
    20::second => now;
    
    //reset
    0=>s1.rate;
    s1.samples()-1 => s1.pos;
    0=>s2.pos;
    0=>s2.rate;
    
    (_interval - 20 - 21)::second => now;
    
    //play tail
    -1=>s1.rate;
    
    21::second => now;

}

