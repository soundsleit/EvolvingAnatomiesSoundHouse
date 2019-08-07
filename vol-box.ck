//this script interfaces a custom volume box to chuck
//for changing the volume of dac

//chuck it along with any chuck script


SerialIO.list() @=> string list[];
SerialIO cereal;

//the name of my arduino box's serial port
"usbserial-12DP0657" => string port;

//number of serial device
-1=>int device;

//loop through any ports and find the one with the right name
for(0=>int i; i < list.cap(); i++)
{
    
    //check for correct port name
    if (list[i].find(port) != -1)
    { 
        //and assign the device number
        i => device;
        break;
    }
    else 
        -1 => device;
}

//open the serial port
cereal.open(device, SerialIO.B57600, SerialIO.ASCII);

//loop through and grab the serial port data
while(true)
{
    cereal.onInts(2) => now;
    cereal.getInts() @=> int ints[];
    
    if (ints != null)
    {
        //chuck state of switch and, if on, allow knob to control dac volume
        if (ints[0]) ints[1]/1000.0 => dac.gain;   
    }
}

