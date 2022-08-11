midi { // musical instrument device interface
    input { // midi input
        note { // note on/off from 0 thru 127
            on  (num 0…127, velo 0…127, chan 1…32, port 1…16, time 0)
            off (num 0…127, velo 0…127, chan 1…32, port 1…16, time 0)
        }
        controller (num 0…127, val 0…127, chan 1…32, port 1…16, time 0)
        afterTouch (num 0…127, val 0…127, chan 1…32, port 1…16, time 0)
        pitchBend  (val 0…16384 = 8192, chan 1…32, port 1…16, time 0)
        programChange (num 0…255, chan 1…32, port 1…16, time 0) //1, 632, 255
    }
    output : input
    cc {
        main {
            modWheel    (num == 1, val, chan, time)
            volume      (num == 7, val, chan, time)
            balance     (num == 8, val, chan, time)
            panPosition (num == 10, val, chan, time)
            expression  (num == 11, val, chan, time)
            controller  (num in 32…63, val, chan, time) // controller 0…31
            portamento {
                time   (num == 5, val, chan, time)
                amount (num == 84, val, chan, time)
            }
        }
        pedal {
            hold    (num == 64, val, chan, time)
            porta   (num == 65, val, chan, time)
            sosta   (num == 66, val, chan, time)
            _soft    (num == 67, val, chan, time)
            _legato  (num == 68, val, chan, time)
            _hold2   (num == 69, val, chan, time)
        }
        _cc {
            _main2 {
                bankSelect  (num == 0, val, chan, time)
                breathCtrl  (num == 2, val, chan, time)
                footPedal   (num == 4, val, chan, time)
                dataEntry   (num == 6, val, chan, time)
                effectControl1 (num == 12, val, chan, time)
                effectControl2 (num == 13, val, chan, time)
            }
            _sound {
                soundVariation  (num == 70, val, chan, time)
                resonance       (num == 71, val, chan, time)
                soundReleaseTime(num == 72, val, chan, time)
                soundAttackTime (num == 73, val, chan, time)
                frequencyCutoff (num == 74, val, chan, time)

                timbre          (num == 71, val, chan, time)
                brightness      (num == 74, val, chan, time)
            }
            _button {
                button1 (num == 80, val, chan, time)
                button2 (num == 81, val, chan, time)
                button3 (num == 82, val, chan, time)
                button4 (num == 83, val, chan, time)

                decayor          (num == 80, val, chan, time)
                hiPassFilter     (num == 81, val, chan, time)
                generalPurpose82 (num == 82, val, chan, time)
                generalPurpose83 (num == 83, val, chan, time)
            }
            _roland {
                rolandToneLevel1 (num == 80, val, chan, time)
                rolandToneLevel2 (num == 81, val, chan, time)
                rolandToneLevel3 (num == 82, val, chan, time)
                rolandToneLevel4 (num == 83, val, chan, time)
            }
            _level {
                reverbLevel  (num == 91, val, chan, time)
                tremoloLevel (num == 92, val, chan, time)
                chorusLevel  (num == 93, val, chan, time)
                detuneLevel  (num == 94, val, chan, time)
                phaserLevel  (num == 95, val, chan, time)
            }
            _parameter {
                dataButtonIncrement       (num == 96, val, chan, time)
                dataButtonDecrement       (num == 97, val, chan, time)
                nonregisteredParameterLSB (num == 98, val, chan, time)
                nonregisteredParameterMSB (num == 99, val, chan, time)
                registeredParameterLSB    (num == 100, val, chan, time)
                registeredParameterMSB    (num == 101, val, chan, time)
            }
            _soundControl {
                soundControl6  (num == 75, val, chan, time)
                soundControl7  (num == 76, val, chan, time)
                soundControl8  (num == 77, val, chan, time)
                soundControl9  (num == 78, val, chan, time)
                soundControl10 (num == 79, val, chan, time)
            }
            _undefined {
                undefined_3       (num == 3       , val, chan, time)
                undefined_9       (num == 9       , val, chan, time)
                undefined_14_31   (num in 14…31  , val, chan, time)
                undefined_85_90   (num in 85…90  , val, chan, time)
                undefined_102_119 (num in 102…119, val, chan, time)
            }
            _mode {
                allSoundOff       (num == 120, val, chan, time)
                allControllersOff (num == 121, val, chan, time)
                localKeyboard     (num == 122, val, chan, time)
                allNotesOff       (num == 123, val, chan, time)
                monoOperation     (num == 126, val, chan, time)
                polyMode          (num == 127, val, chan, time)
            }
            _omni {
                omniModeOff       (num == 124, val, chan, time)
                omniModeOn        (num == 125, val, chan, time)
                omniMode(0…1) << (omniModeOff(0), omniModeOn(1))
            }
        }
    }
}
