√ {
    panel {
        _cell {
            base { type "cell"  title "_cell"  frame   icon "icon.ring.white.png"  }
            controls {
                hide { type "panelx"  title "hide"  frame   icon "icon.thumb.X.png"  value (0..1)  }
                ruleOn { type "panelon"  title "Active"  frame   icon "icon.ring.white.png"  value (0..1)  >> panel.cell˚ruleOn.value(0) lag (0)  }
                version { type "segment"  title "Version"  frame   value (0..1 = 1)  user  >> ruleOn.value(1) }
                lock { type "switch"  title "Lock"  frame
                    icon { off "icon.lock.closed.png"  on "icon.lock.open.png"  }  value (0..1)  lag (0)  }
                bitplane { type "slider"  title "Bit Plane"  frame   icon "icon.pearl.white.png"  value (0..1)  >> sky.shader.color.buffer.bitplane }
                fillZero { type "trigger"  title "Fill Zeros"  frame   icon "icon.drop.gray.png"  value (0..1)  >> sky.draw.screen.fillZero }
                fillOne { type "trigger"  title "Fill Ones"  frame   icon "icon.drop.gray.png"  value (0..1)  >> sky.draw.screen.fillOne }  }  }  cell {
                    fade {
                        base { type "cell"  title "Fade"  frame   icon "icon.cell.fade.png"  }
                        controls {
                            hide { type "panelx"  title "hide"  frame   icon "icon.thumb.X.png"  value (0..1)  }
                            ruleOn { type "panelon"  title "Active"  frame   icon "icon.cell.fade.png"  value (0..1)  >> panel.cell˚ruleOn.value(0)  >> sky.shader.fade.on lag (0)  }
                            version { type "segment"  title "Version"  frame   value (0..1 = 0.5)  >> sky.shader.fade.buffer.version user  >> ruleOn.value(1) }
                            lock { type "switch"  title "Lock"  frame
                                icon { off "icon.lock.closed.png"  on "icon.lock.open.png"  }  value (0..1)  lag (0)  }
                            bitplane { type "slider"  title "Bit Plane"  frame   icon "icon.pearl.white.png"  value (0..1 = 0.2)  >> sky.shader.color.buffer.bitplane }
                            fillZero { type "trigger"  title "Fill Zeros"  frame   icon "icon.drop.gray.png"  value (0..1)  >> sky.draw.screen.fillZero }
                            fillOne { type "trigger"  title "Fill Ones"  frame   icon "icon.drop.gray.png"  value (0..1)  >> sky.draw.screen.fillOne }  }  }  }  }  }
