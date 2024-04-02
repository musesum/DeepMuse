DeepMuse is a platform to perform live visual music on iOS, iPadOS, and now visionOS. 

It has elements of old and new, plus some missing bits. 

    Old stuff 
    
        Cellular Automata (CA) shaders. Sometimes referred to as Artificial Life, due to a popular CA called "The Game of Life". I like to think of CAs as kind of neural net in flatland. How it works is that each pixel looks at its neighbors to determine it how to change its color. CA's have been used to model turbulent flow, genetic drift, even sub-quantum phenomenon. Steve Wolfram explored CA to theorize a new kind of physics.
       
       Cube Map
            In DeepMuse, CAs form 2D surface that gets mapped into a cube. This is the background surface that you see. Cubemaps are somewhat old school, usually replaced by spherical mesh. Be that as is may, a cubemap are fairly performant. Instead of copying pixels to the cube, DeepMuse's cubes contain indices that point to a 2D texture. So, copying is done in the shader. That means DeepMuse can played on older devices, including the last generation iPod Touch. Perhaps even Apple TV. 
            
        Platonic solids 
        
            This a mere curiosity: How to morph between the 5 platonic solids. So, moving between tetrahedron, octahedron, cube, dodecahedron, and icosahedron. After each cycle through the 5 solids, Platonic will sub-divide each triangle into 3 sub-triangle. These subdivisions are kind of like the audio overtone series. So, they're called harmonics.
                 
        
        Environment and Object 
        
            Right now, DeepMuse has only Environment and one Object. The Cubemap is the environment with a morphing Platonic as the object. This is fine for very abstract performances. Particularly when the object reflects the environment. When you move inside the object, it turns into a trippy kaleidoscope. But it doesn't need to stop there. 
            
            
        Data Flow Patching
            The first analog music synthesizers used patch cords. You would connect different modules together, like from an oscillator to a filter to an envelope generator to an amplifier. These modules worked within a standard voltage levels. So, the scaler ranges were always are the same. 
            
            In the digital realm, where a MIDI note has a range between 0 and 127, whereas the screen may have 1920x1280 pixels. So, the scripting language (DSL) allows you to declare the ranges for each module, and patching will auto remap between the ranges. The Swift Package MuFlo, explains other features, like breaking loops and synchronizing between devices. 
            
        Asteroids -- The game environment
        
            Well actually toroidal environment, but "Asteroids" sounds more fun. As per chatGPT "Asteroids," released by Atari in 1979. In "Asteroids," players control a spaceship in an asteroid field, and both the spaceship and asteroids would reappear on the opposite side of the screen if they moved past the screen's edges. 
            
            Getting back to the Cellular Automata, there is an option to move the CA universe in any direction, per frame. Touching on the canvas, during this shift, will appear to leave something like a jet contrail. Shift fast enough, and the dots will fill the screen. Kinda of fun. You can set the shift manually. Or, on the iPad, map the to the pencil tilt to the pencil. There isn't anything like pencil tilt on the Vision Pro. Yet. 
            
                By the way, double tapping on the menu will reset the value for screen shift back to normal (no shift). Which leads us to some new stuff: 
                
            
    New Stuff
        
        Menu Palettes
        
            The original DeepMuse synth, from 20 years ago, mapped the controls to a Wacom Graphics Tablet. It supported control of around 2800 parameters. And yet, I could put the tablet in the hands of a 12-year-old, who could figure out how to perform with it in a few minutes. 
            
            The advantage of the static palette is that you could develop muscle memory.The downside is that you would have to look down at the palette so select a context for those parameters. So, nowhere near the 20 millisecond response time that a touch typist takes to hit a key on a normal keyboard. It was rather unwieldy. 
            
            So, let's rethink menus. A menu is basically a tree of sub-menus. You have to jump from branch to branch before landing on a leaf. Only then can you do something. But what if the tree knows where you have been before?  Now, while moving up the trunk of the tree, its branches and sub-branches automatically unfold to your last visited leaf. 
            
            Getting back to those 2800 parameters on the Wacom tablet. Let's start with a hypothetical a menu, with an average of 5 choices going 5 levels deep. That would support a total of 5^5, or 3125 leaves. Moreover, because each branch saves the most recent subbranch, that menu could save 5^4, 625 bookmarks. Most likely, reaching a particular leaf would need only a couple of steps -- about half as many as a normal menu. 
            
            There's more: 
            
            Each leaf has a default behavior. In the Asteroids style shifting control, mentioned above, double-tapping on the parent branch will reset the shift to a complete standstill. Moreover, double-tapping on the grandparent, great grandparent, and so on, will also pass through that request to stop shifting.
                
            Over time, and as long as the menu stays constant, you begin to develop a kind of muscle memory, akin to touch typing on a keyboard. This overcomes some problems with a purely virtual input, where there aren't fixed controls. Which brings us to what's wrong with spatial interfaces, next.
        
        
        Handpose 
            
            VisionOS provides the first workable hand-pose. But, as with any visual UI, it requires shifting gaze to an object to select it. During this Eye Saccade, you are  blind for 200 milliseconds. Compare this with a touch typist that can tap a key in 20 msec. One workaround is to use mixed modal input with voice. 
            
            While not perfect, the DeepMuse menuing system (MuMenu) helps reduce to number of steps. The more perfect solution will be discussed is not yet implements. Stay tuned. 
            
    Missing bits -- bugs and features
    
        Bugs
            Menus. The iPad and iOS versions of DeepMuse can synchronize menus selections. But the visionOS does not. Why? Because we had to move the root menu from the lower part of the window to the upper part. Otherwise, looking at the lower corners would be interpreted by visionOS as intending to resize the window and would add grab points. It was nearly impossible to select the root menu icon. So, it was moved to the top. The problem is that the identity of a gesture was based on which corner is started from. Need to fix that soon. 
            
            Phantom controls. In the visionOS version, there is a camera control that doesn't work. VisionOS doesn't allow camera. Not sure of the fix. Could take it out, but that would ruin the static nature of sharing controls.
            
            Touch mapping to canvas. 
            
                In visionOS, touching thumb and index finger tips will draw in Passthrough mode, but not in Immersive mode. Instead, you have to touch thumb and middle finger. 
                
                With the cubemap's canvas, drawing by pinching on thumb and finger should paint on where you expect it to. That would be where you see your pinch overlapping the canvas. It doesn't. So, with feels random. It merely requires some math around sight lines and suck. 
                
                The 2D canvas doesn't work -- only with cubemap. It used to work on the Pad, which was useful for drawing with the Apple Pencil. In fact it was pretty cool. Instead, started to focus on maintaining consistency between the iPad and the immersive space on the visionPro. This is really important for the social model, which we will get to next. 
                
The social model

    DeepMuse is a toy that aspires to be a platform. The basic premise is that all players share a view into a shared space. It doesn't matter whether that view is through an iPhone, iPad, or Vision Pro. Maybe even an Apple TV could get into the act -- given that the rendering pipeline is simple and performant. The result is a collaborative performance, which renders the exact same environment on player's device. Pixel perfect. 
    
    And not limited to Apple devices. With AudioKit, anyone with a midi instrument can join the fun. 
    
   As for the VisionPro, the result is unexpected. Instead of being an isolating device, the VisionPro becomes a collaborative hub. Where, the wearer is like a conductor, waving their hands to orchestrate the performance. 
            
            
Future -- TBD
