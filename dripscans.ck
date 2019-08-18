// ********************************** //
// dripscans
// for Dyscorpia: Evolving Anatomies Sound House
// Dec. 2018 - Feb. 2019 by (cc) Scott Smallwood

// stupid MOTU offset
2=>int offset;

//how many files are there to choose from?
16=>int fileMax;

//how many channels
4 => int audioChannels;
//the initial volume
.05=>float initVolume;

//check for command line arguments and if found, set appropriate vars
if (me.args() > 0)
{
    Std.atof(me.arg(0)) => initVolume;
    Std.atoi(me.arg(1)) => offset;
}

SndBuf s;
ADSR e;
Gain gs[audioChannels];
Gain g[audioChannels];
e.set(5000::ms, 0::ms, 1, 5000::ms);
s.loop(1);

for (0=> int i; i<audioChannels; i++)
{
    s => e => gs[i] => g[i] => dac.chan(i+offset);
    initVolume * .1 => g[i].gain;
}

while (true)
{
    Math.random2(5000,20000)::ms => now;
    Math.random2(10000,30000)::ms => dur len;
    spork ~ QuadPanner(len);
    len => now;
    Math.random2(5000,20000)::ms => now;
}


//makes the drip sound move around the speakers
fun void QuadPanner(dur _len)
{
    //determine soundfile, and set position randomly
    "snd/dripscans/snd" + Math.random2(0,fileMax-1) + ".wav" => s.read;
    Math.random2(0,s.samples()-1) => s.pos;
    
    //time accumulator
    0::ms => dur accum;
    
    //adjust playback time to accommodate env release
    _len - e.releaseTime() => _len;
    
    //the ramper
    Phasor cr => blackhole;
    
    //randomly set initial freq and phase
    Math.random2f(0,1) => cr.phase;
    Math.random2f(.1,.5)=>cr.freq;
    
    //trigger envelope
    e.keyOn(1);
    
    while (accum < _len)
    {
        //use to adjust ramp on final channel
        0=>float adj;
        //the phaser control ramp
        cr.phase() => float ramp;
        
        Math.min(ramp*2-0.,1.0) => float ramp1;
        Math.max(ramp1,0.0) => ramp1;
        if (ramp1 < .5) ramp1 * 2 => ramp1;
        else if (ramp1 > .5) ((ramp1 - 1) * -1) *2 => ramp1;
        
        Math.min(ramp*2-.5,1.0) => float ramp2;
        Math.max(ramp2,0.0) => ramp2;
        if (ramp2 < .5) ramp2 * 2 => ramp2;
        else if (ramp2 > .5) ((ramp2 - 1) * -1) *2 => ramp2; 
        
        Math.min(ramp*2-1.0,1.0) => float ramp3;
        Math.max(ramp3,0.0) => ramp3;
        if (ramp3 < .5) ramp3 * 2 => ramp3;
        else if (ramp3 > .5) ((ramp3 - 1) * -1) *2 => ramp3;
        
        if (ramp < .25) 1.=>adj;
        else 0.=>adj;
        Math.min((ramp+adj)*2-1.5,1.0) => float ramp4;
        Math.max(ramp4,0.0) => ramp4;
        if (ramp4 < .5) ramp4 * 2 => ramp4;
        else if (ramp4 > .5) ((ramp4 - 1) * -1) * 2 => ramp4;
        
        ramp1 => gs[0].gain;
        ramp2 => gs[1].gain;
        ramp3 => gs[3].gain;
        ramp4 => gs[2].gain;
        
        1::samp + accum => accum;
        1::samp => now;
    }
    
    e.keyOff(1);
    e.releaseTime() => now;
    
    for (0=>int i; i<audioChannels; i++)
        0=>gs[i].gain;
}


