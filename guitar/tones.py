#!/usr/bin/python
"""Play pitchs (or guitar strings).

$ python tones.py a4 | bplay
$ python tones.py 3 | bplay 

(assumes bplay is 16bits/mono/8000sps)
"""
import re
import sys
import math
import struct
import itertools

# pitch = (str-note, int-octave) 

# if you need sharp notes, create a dictionary with pairs (name, index) instead
notes = "c c# d d# e f f# g g# a a# b".split()
# pitch = (node, octave)

# +3 because of the 3 semitones between the reference A0 (27.5Hz) and C1
factors_from_c0 = dict((note, 27.5 * 2**(((idx + 3) / 12.0) - 1)) 
                       for (idx, note) in enumerate(notes)) 

def get_frequency(pitch):    
    """Get frequency for pitch."""
    note, octave = pitch
    return 2**octave * factors_from_c0[note]

def get_pitch(s):
    """Split string pitch into a tuple of integers (note, octave)."""
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
            # It's a digit, assume it's the index of the standard guitar tuning
            guitar_string_strpitchs = "e4 a4 d5 g5 b5 e6".split()
            strpitch = guitar_string_strpitchs[int(strpitch)-1]
    else:
        # No args, play A4 concert (440Hz), the musical default pitch
        strpitch = "a4"
    debug("pitch: %s" % strpitch)
    frequency = get_frequency(get_pitch(strpitch))
    for audio in sin_generator(frequency, samplerate=8000):
        sys.stdout.write(audio)
    
if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
