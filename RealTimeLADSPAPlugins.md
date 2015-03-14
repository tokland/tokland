# Introduction #

Apply real-time [LADSPA](http://www.ladspa.org/) plugins to your soundcard output using [ALSA](http://www.alsa-project.org/main/index.php/Main_Page).

# Install #

  * Install [alsaequal](http://www.thedigitalmachine.net/alsaequal.html).
  * Edit your _$HOME/.asoundrc_ to set up the _equal_ plug. The following example introduces a line delay up to 60 seconds (you'll need [cmt plugins](http://www.ladspa.org/cmt/) also):

```
ctl.equal {
  type equal;
  library "/usr/lib/ladspa/cmt.so";
  module "delay_60s";
}

pcm.plugequal {
  type equal;
  slave.pcm "dsp0";
  library "/usr/lib/ladspa/cmt.so";
  module "delay_60s";
}

pcm.equal {
   type plug;
   slave.pcm plugequal;
}

pcm.dsp0 {
    type plug
    slave.pcm "dmix"
    hint {
         show on
         description "My dmix dsp0"
    }
}
```

# Usage #

Instruct your multimedia application to use ALSA and the _equal_ device, for example:

```
$ mplayer -ao alsa:device=equal video.avi 
```

And now you can finally modify setting real-time with alsamixer:

```
$ alsamixer -D equal
```