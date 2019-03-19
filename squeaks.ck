// ********************************** //
// squeaks
// for Dyscorpia: Evolving Anatomies Sound House
// Dec. 2018 - Feb. 2019 by (cc) Scott Smallwood

// stupid MOTU offset
2=>int offset;
//the initial volume
.05=>float initVolume;

//how many channels
4 => int audioChannels;

//the patch
SndBuf sb[audioChannels];
SndBuf ss[audioChannels];
Gain g[audioChannels];
Gain g2[audioChannels];

//the phaser control (for vol swell)
Phasor p => blackhole;

for (0=>int i; i<audioChannels; i++)
{
    sb[i]=>g[i]=>g2[i]=>dac.chan(i+offset);
    ss[i]=>g[i];
    "snd/squeakies/squeaky_background_loop_" + i + ".wav" => sb[i].read;
    0 => sb[i].pos;
    0 => sb[i].rate;
    0 => g[i].gain;
    0 => g2[i].gain;
}

spork ~ playBackground();
spork ~ playSqueaks();


//over time, random silence, followed by slow fade up and down
while (true)
{
    Math.random2(20000,30000)::ms => now;
    VolFader();
}

fun void VolFader()
{
    //reset phasor
    0=>p.phase;
    
    //set freq of phaser
    Math.random2f(.005,.01)=>p.freq;
    
    while (p.phase()<.999)
    {
        //create curved ramp
        Math.sin(p.phase()*Math.PI) => float amp;
        
        //set the gain
        for (0=>int i; i<audioChannels; i++)
        {
            amp => g2[i].gain;
        }
        //move time at audio rate
        1::samp => now;
    }
    
    //reset gain
    for (0=>int i; i<audioChannels; i++)
    {
        0 => g2[i].gain;
    }
    
}

fun void playBackground()
{
    for (0=>int i; i<audioChannels; i++)
    {
        .5 => sb[i].gain;
        0 => sb[i].pos;
        1 => sb[i].rate;
        initVolume => g[i].gain;
        sb[i].loop(1);
    }
    
}

fun void playSqueaks()
{
    while(true)
    {
        for (0=>int c; c<audioChannels; c++)
        {
            "snd/squeakies/squeaky_squeak-" + Math.random2(0,11) + "_" + (c + 1) + ".wav" => ss[c].read;
            .5 => sb[c].gain;
             0 => ss[c].pos;
             1 => ss[c].rate;
             initVolume => g[c].gain;
        }
        
        45::second => now;
        
    }
}


