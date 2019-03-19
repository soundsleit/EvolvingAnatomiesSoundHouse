// ********************************** //
// house_fabrics
// for Dyscorpia: Evolving Anatomies Sound House
// Dec. 2018 - Feb. 2019 by (cc) Scott Smallwood


// stupid MOTU offset
2=>int offset;
//the initial volume
.05=>float initVolume;

// channels
4 => int audioChannels;
4 => int voices;

// tuning system magic numbers
//partials per voice
8  => int partials;
//2474/16. => float baseFundamental;

//YES
167 => float baseFundamental;
2 => float baseFactor;
3 => int bases;
5 => int baseStep;
// init reverb mix
.01 => float verb;
// size of freq ridge (deviation, or drift)
.001 => float devi;
// time between freq mods
30 => int ridgeSize;


// total pitches
(bases - 1) * baseStep => int stepMax;

// main pitch table
float step[stepMax];

// random number seed
Std.rand2f(.01,.09) => float seed;
seed::second => now;

// **** AUDIO CHAIN

// oscillator array
SinOsc s[voices][partials];
// main gain
Gain g[audioChannels];
// envelopes per channels
ADSR e[audioChannels];
// reverberators per channels
JCRev mainRev[audioChannels];
// submaster gains voice
Gain sub[voices];
// pans per voice
Pan2 p[voices];

// stereo chain
if (audioChannels == 2)
{
    // main bus setup
    for (0 => int i; i < audioChannels; i++) {
        g[i] => e[i] => mainRev[i] => dac.chan(i+offset);
        initVolume => g[i].gain;
        verb => mainRev[i].mix;
        e[i].set(50::ms, 0::ms, 1, 50::ms);
    }
    
    // voice assignments and panning
    for (0 => int i; i < voices; i++) {
        // spread voices evenly across field
        (((1. / (voices - 1)) * i) * 2) - 1 => p[i].pan;
        sub[i] => p[i].left => g[0];
        sub[i] => p[i].right => g[1];
        1 => sub[i].gain;
    }
}

// multi-channel chain
else
{
    // main bus setup
    for (0 => int i; i < audioChannels; i++) {
        sub[i] => g[i] => e[i] => mainRev[i] => dac.chan(i+offset);
        e[i].set(500::ms, 0::ms, 1, 500::ms);
        initVolume => g[i].gain;
        .3 => sub[i].gain;
        verb => mainRev[i].mix;
    }
}

float partialgain_current[partials];
float partialgain_target[partials];

for (0 => int i; i < voices; i++) 
    for (0 => int j; j < partials; j++){
        1./partials => s[i][j].gain => partialgain_target[j];
        partialgain_target[j] 	=>  partialgain_current[j];
    }
    
    // control events
    Event fabOn, fabOff, screenFresh;
    
    // main volume knob
    0.0 => float volMain;
    
    1::second => now;
    
    // **** MODULES
    
    //spork ~ screenPanel();
    spork ~ pitchFabOn();
    spork ~ pitchFabOff();
    spork ~ modulator();
    spork ~ deviator();
    //spork ~ KeyControl();
    for (0=>int i; i<partials; i++)
        spork ~ GainFader(i);
    
    1::second => now;
    
    fabOn.signal(); //turn on on startup
    
    1::day => now; //hang out
    
    
    
    // ********* FUNCTIONS ********* FUNCTIONS ********* FUNCTIONS ********* FUNCTIONS 
    // #### 
    // ####
    
    fun void KeyControl()
    {
        Hid hi;
        HidMsg msg;
        
        for (0=>int i; i<99; i++)
        {
            if (hi.openKeyboard(i)) 
                if (hi.name() == "USB Keyboard")
                {
                    <<<"keyboard " + hi.name() + " ready", "">>>;
                    break;
                }
            }
            
            while (true)
            {
                hi=>now;
                while (hi.recv(msg))
                {
                    if (msg.isButtonDown())
                    {
                        if (msg.ascii == 90) 
                        {
                            fabOff.signal();
                        }
                        if (msg.ascii == 88) 
                        {
                            fabOn.signal();
                        }
                        
                    }
                }
            }
        }
        
        //gentle ramps on all partials
        fun void GainFader(int _partial)
        {
            
            while (true) {
                for (0=>int x; x < 100; x++)
                {
                    for (0=>int i; i<voices; i++)
                    {
                        s[i][_partial].gain() + .001 => s[i][_partial].gain;
                    }
                    Math.random2(100,800)::ms => now;
                }
                for (0=>int x; x < 100; x++)
                {
                    for (0=>int i; i<voices; i++)
                    {
                        s[i][_partial].gain() - .001 => s[i][_partial].gain;
                    }
                    Math.random2(100,800)::ms => now;
                }
            }
        }
        
        // **** CREATE PITCH FABRIC
        
        fun void pitchFabOn()
        {
            while (true)
            {
                fabOn => now;
                
                for (0 => int i; i < voices; i++)
                    spork ~ buildWave(i, (1. / voices));
                
                for (0 => int i; i < audioChannels; i++)
                    1 => e[i].keyOn;
            }
        }
        
        fun void pitchFabOff()
        {
            while (true)
            {
                fabOff => now;
                
                for (0 => int i; i < audioChannels; i++)
                    1 => e[i].keyOff;
            }
        }
        
        
        fun void resetFab()
        {
            fabOff.signal();
            e[0].releaseTime() => now;
            fabOn.signal();
        }
        
        
        
        
        // #### 
        // ####
        
        
        fun void buildWave(int wavNum, float baseGain)
        {
            
            // ## POPULATE ARRAY OF PITCHES (step) **
            
            //baseFundamental * Std.rand2(1,3) => float base;
            baseFundamental => float base;
            0 => int k;
            
            for (1 => int i; i < bases; i++)
            {
                for (0 => int j; j < baseStep; j++)
                {
                    base + (j * (((base * baseFactor) - base) / baseStep)) => step[k];
                    k++;
                }
                base * baseFactor => base;
            }
            
            // ## Build Additive Waveforms
            
            //  * partials - number of components
            //  * wavNum - this waveform (current)
            //  * baseGain - the gain threshold of this stage
            
            Std.rand2(0, stepMax / 2) => int startStep; // pick any freq from first half
            (stepMax - startStep) / partials => int partInv; // interval size btw partials
            
            // assign partial freqs, gain, and assign to channel
            for (0 => int i; i < partials; i++)
            { 
                s[wavNum][i] =< sub[wavNum];
                s[wavNum][i] => sub[wavNum];
                step[startStep + (partInv * i)] => s[wavNum][i].freq;
                (1. / (i + 1)) * baseGain  => s[wavNum][i].gain;
            }
            
        }
        
        // ####
        // ####
        
        // modulates freq of all of the oscs a tiny bit, randomized
        fun void modulator()
        {
            while (true)
            {	
                for (0 => int j; j < voices; j ++)
                {
                    for (0 => int k; k < partials; k++)
                        //add little bits to the freq - brownian-like
                        s[j][k].freq() + Std.rand2f(-devi * (k + 1), devi * (k + 1)) 
                        => s[j][k].freq;
                }
                //how long between drifts
                ridgeSize * Std.rand2f(0.9, 1.1)::ms => now;
            }
        }
        
        // ####
        // ####
        
        // deviator slowly increases the amount of drift
        fun void deviator()
        {
            while (true)
            {
                devi + .00001 => devi;
                1::second => now;
            }
        }
        
             
        
        // ####
        // ####
        
        
        fun void screenPanel()
        {
            
            while (true) {
                
                for (0 => int i; i < 40; i++)
                    <<< " ", " " >>>;
                
                <<< "                  !!! F A B R I C S !!!", " " >>>;
                <<< "    ++++++++++++++++++++++++++++++++++++++++++++++++++++", " " >>>;
                <<< " ", " " >>>;
                <<< "                      ", audioChannels, " channels">>>;
		<<< "              ", partials, " partials per ", voices, " voices.">>>;
		<<< "              ", baseFundamental, " Hz., ", bases, " bases.">>>;
		<<< "          Base ratio of ", baseFactor, ". ", baseStep, " scale members.">>>;
		<<< " ", " " >>>;
		<<< "         Voices and their first four partials:", " ">>>;
		<<< " ", " " >>>;
		for (0 => int v; v < voices; v++)
				<<<"{", s[v][0].freq(), "} ","{", s[v][1].freq(), "} ","{", s[v][2].freq(), "} ","{", s[v][3].freq(), "} ">>>;
		<<< " ", " " >>>;
        <<< " ", " " >>>;
        <<< "                              drift ", " {", devi, "}" >>>;
		<<< " ", " " >>>;
        		<<< "         Partial Gains for All Voices (0-7):", " ">>>;
		<<<"{ ", s[0][0].gain(), " }", "{ ", s[0][1].gain(), " }", "{ ", s[0][2].gain(), " }", "{ ", s[0][3].gain(), " }">>>;
		<<<"{ ", s[0][4].gain(), " }", "{ ", s[0][5].gain(), " }", "{ ", s[0][6].gain(), " }", "{ ", s[0][7].gain(), " }">>>;
		<<< " ", " " >>>;
		<<< "    ++++++++++++++++++++++++++++++++++++++++++++++++++++", " " >>>;
		<<< " ", " " >>>;
		<<< "                 OFF ON/RESET ", " ">>>;
		<<< "                  -  +    ", " ">>>;
		<<< "                 [z][x]       ", " " >>>;
		<<< " ", " " >>>;
		<<< " ", " " >>>;

		<<< "    ++++++++++++++++++++++++++++++++++++++++++++++++++++", " " >>>;
		<<< " ", " " >>>;

		50::ms => now;
	}
	
}





