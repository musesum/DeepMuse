sky  # base for visual music synthesize
    midi  # musical instrument device interface
        frame (num + 1) # frame counter
        input  # midi input
            note  # note on/off from 0 thru 127
                on  (num 0..127, velo 0..127, chan 1..32, port 1..16, time 0)
                off (num 0..127, velo 0..127, chan 1..32, port 1..16, time 0)

            controller (num 0..127, val 0..127, chan 1..32, port 1..16, time 0)
            afterTouch (num 0..127, val 0..127, chan 1..32, port 1..16, time 0)
            pitchBend  (val 0..16384 = 8192, chan 1..32, port 1..16, time 0)
            programChange (num 0..255, chan 1..32, port 1..16, time 0) # 1, 632, 255

        output: [input] <: input # midi output copy of input and mapped by name

        input.controller >> cc.*  # dispatch to each included mixin of _*
                                  # which filters based on `num == n` so:
                                  # controller(num   64 val 127 chan 1 port 1 12345) updates
                                  # holdPedal(num == 64 val     chan   port        ) to
                                  # holdPedal(num == 64 val 127 chan 1 port 1 12345)

        cc: [_main, _pedal]
            _main
                bankSelect       (num == 0, val, chan, time)
                modulationWheel  (num == 1, val, chan, time)
                breathController (num == 2, val, chan, time)
                footPedal        (num == 4, val, chan, time)
                portamentoTime   (num == 5, val, chan, time)
                dataEntry        (num == 6, val, chan, time)
                volume           (num == 7, val, chan, time)
                balance          (num == 8, val, chan, time)
                panPosition      (num == 10, val, chan, time)
                expression       (num == 11, val, chan, time)

                controller       (num == 32..63, val, chan, time) # controller 0..31
                portamentoAmount (num == 84, val, chan, time)

            _main2  # _cc removes from dispatch change to cc._sound to include
                effectControl1   (num == 12, val, chan, time)
                effectControl2   (num == 13, val, chan, time)

            _pedal
                holdPedal       (num == 64, val, chan, time)
                portamento      (num == 65, val, chan, time)
                sostenutoPedal  (num == 66, val, chan, time)
                softPedal       (num == 67, val, chan, time)
                legatoPedal     (num == 68, val, chan, time)
                hold2Pedal      (num == 69, val, chan, time)
                _pedal.* >> print.nodeVal

            _sound  # _cc removes from dispatch change to cc._sound to include
                soundVariation  (num == 70, val, chan, time)
                resonance       (num == 71, val, chan, time)
                soundReleaseTime(num == 72, val, chan, time)
                soundAttackTime (num == 73, val, chan, time)
                frequencyCutoff (num == 74, val, chan, time)

                timbre          (num == 71, val, chan, time)
                brightness      (num == 74, val, chan, time)

            _button  # _cc removes from dispatch change to cc._sound to include
                button1 (num == 80, val, chan, time)
                button2 (num == 81, val, chan, time)
                button3 (num == 82, val, chan, time)
                button4 (num == 83, val, chan, time)

                decayor          (num == 80, val, chan, time)
                hiPassFilter     (num == 81, val, chan, time)
                generalPurpose82 (num == 82, val, chan, time)
                generalPurpose83 (num == 83, val, chan, time)

            _roland  # _cc removes from dispatch change to cc._sound to include
                rolandToneLevel1 (num == 80, val, chan, time)
                rolandToneLevel2 (num == 81, val, chan, time)
                rolandToneLevel3 (num == 82, val, chan, time)
                rolandToneLevel4 (num == 83, val, chan, time)

            _level  # _cc removes from dispatch change to cc._sound to include
                reverbLevel  (num == 91, val, chan, time)
                tremoloLevel (num == 92, val, chan, time)
                chorusLevel  (num == 93, val, chan, time)
                detuneLevel  (num == 94, val, chan, time)
                phaserLevel  (num == 95, val, chan, time)

            _parameter  # _cc removes from dispatch change to cc._sound to include
                dataButtonIncrement       (num == 96, val, chan, time)
                dataButtonDecrement       (num == 97, val, chan, time)
                nonregisteredParameterLSB (num == 98, val, chan, time)
                nonregisteredParameterMSB (num == 99, val, chan, time)
                registeredParameterLSB    (num == 100, val, chan, time)
                registeredParameterMSB    (num == 101, val, chan, time)

            _soundControl  # _cc removes from dispatch change to cc._sound to include
                soundControl6  (num == 75, val, chan, time)
                soundControl7  (num == 76, val, chan, time)
                soundControl8  (num == 77, val, chan, time)
                soundControl9  (num == 78, val, chan, time)
                soundControl10 (num == 79, val, chan, time)

            _undefined  # _cc removes from dispatch change to cc._sound to include
                undefined_3       (num == 3       , val, chan, time)
                undefined_9       (num == 9       , val, chan, time)
                undefined_14_31   (num in 14..31  , val, chan, time)
                undefined_85_90   (num in 85..90  , val, chan, time)
                undefined_102_119 (num in 102..119, val, chan, time)
             # _cc removes from dispatch change to cc._sound to include
            _mode  /* (on/off) */
                allSoundOff       (num == 120, val, chan, time)
                allControllersOff (num == 121, val, chan, time)
                localKeyboard     (num == 122, val, chan, time)
                allNotesOff       (num == 123, val, chan, time)
                monoOperation     (num == 126, val, chan, time)
                polyMode          (num == 127, val, chan, time)

            _omni  # _cc removes from dispatch change to cc._sound to include
                omniModeOff       (num == 124, val, chan, time)
                omniModeOn        (num == 125, val, chan, time)
                omniMode(0..1) << (omniModeOff(0), omniModeOn(1))


        instrument <: input.note  # assign notes to instrument based on channel
            piano  # receive all channel 1 midi notes
                on  (num, velo, chan == 1, time)
                off (num, velo, chan == 1, time)

            vibraphone  # receive all channel 2 midi notes
                on  (num, velo, chan == 2, time)
                off (num, velo, chan == 2, time)

            xylophone  # receive all channel 3 midi notes
                on  (num, velo, chan == 3, time)
                off (num, velo, chan == 3, time)

            marimba  # receive all channel 4 midi notes
                on  (num, velo, chan == 4, time)
                off (num, velo, chan == 4, time)

        split :> output.note    # example of split keyboard
                                # where piano is first 2 octaves
                                # followed by vibraphone,
                                # xylophone, marimba

            piano <: input.note
                on  (num in 0..23, num + 24, velo, chan, time)
                off (num in 0..23, num + 24, velo, chan, time)

            vibraphone <: input.note
                on  (num in 24..48, num 24..48, velo, chan, time)
                off (num in 24..48, num 24..48, velo, chan, time)

            xylophone <: input.note
                on  (num in 48..60, num - 48, velo, chan, time)
                off (num in 48..60, num - 48, velo, chan, time)

            marimba <: input.note
                on  (num in 60..71, num 12..23, velo, chan, time)
                off (num in 60..71, num 12..23, velo, chan, time)


        # seq[input.programChange.num] << (cc.hold2Pedal ? midi.input˚.)

        arp  # create an appegiator: `piano >> vibes >> xylo >> marimba

            notes (24) # total notes looping through
            duration (1.0) # whole note seconds

            nums  (0,   7,  7,  7, -5, -5, -5)
            velos (1., .9, .8, .7, .6, .5, .4)
            chans (1,   2,  2,  3,  3,  3,  3)
            durs  (/1, /2, /2, /4, /4, /4, /4) << duration

            input.note :> play (num, velo, chan, time, i = 0)

            play: input.note
            play [on, off] (num  + nums[i],
                            velo * velos[i],
                            chan + chans[i],
                            time + durs[i],
                            i < notes, i + 1) :>>> play

            .* :> output.note   # midi output on and off
            .* >> print.nodeVal # print node and value to console
