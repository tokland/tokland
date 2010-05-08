#!/usr/bin/python
"""Play pitchs (or guitar strings).

$ python tones.py a4 | bplay

$ python tones.py 3 | bplay 

(assumes bplay defaults to sample rate 8000Hz)
"""
import re
import sys
import math
import struct
import itertools

# pitch = (str-note, int-octave) 
 
notes = "c c# d d# e f f# g g# a a# b".split()

# +3 because of the 3 semitones between A0 (27.5Hz) and C1
factors_to_c0 = dict((note, 27.5 * 2**(((idx+3)/12.0) - 1)) 
    for (idx, note) in enumerate(notes)) 

def get_frequency(pitch):    
    """Get frequency for pitch."""
    note, octave = pitch
    return 2**octave * factors_to_c0[note]

def get_pitch(s):
    """Split pitch in (note, octave) tuple."""
    note, octave = re.match("([a-g]#?)(\d+)$", s.lower()).groups()
    assert note in notes
    return note, int(octave) 

###

def debug(s):
    """Write line to standard errror."""
    sys.stderr.write(str(s)+"\n")
  
def sin_generator(freq, amplitude=0.5, bufsize=256, samplerate=8000):
    """Yield sinusoidal audio data (16-bit signed samples)."""
    iamplitude = amplitude * (2**15) 
    k = (2 * math.pi * freq) / samplerate
    debug("sin: %s Hz" % freq)
    for index in itertools.count(0):
        ts = range(index*bufsize, (index+1) * bufsize)
        values = [iamplitude * math.sin(k * t) for t in ts]
        yield struct.pack("%dh" % bufsize, *values)

def main(args):
    if args:
        strpitch = args[0]
        if strpitch.isdigit():
            guitar_string_strpitchs = "e4 a4 d5 g5 b5 e6".split()
            strpitch = guitar_string_pitchs[int(strpitch)-1]
    else:
        strpitch = "a4" 
    debug("pitch: %s" % strpitch)
    for data in sin_generator(get_frequency(get_pitch(strpitch))):
        sys.stdout.write(data)
    
if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
