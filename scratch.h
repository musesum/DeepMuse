
Album: 
   swap icons to : photo.on.rectangle.angled
   modal picker gets stuck and cannot dismiss, 
       "select up to 8 photos" no access to menu
        X and checkmark have no effect
Draw position needs to account for Canvas.Repeat value

Camera Bugs
    foreground shows very dark foreground
    Background not showing
Layer Routing has:
    Headline
        Center Title "Layers"
        Add name of element user is editing while editing
    Inputs // showing raw in big square
        Draw(D) { real r, false f }
        Camera(C) {Forground, Background }
        Album(A) {Forground, Background }
    Filters for
        Foreground(F)
        Background(B)
        Raw(R)
    Paths
        Above(a) // small square to right of Input above b
        Below(b) // small square to right of INput below a
    Outputs // radio button to right of a or b, using Dreamatic icons
        Empty 0
        Raw 1
        Gen 2 // grayed out
        Cell 3 // use square.grid.3x3.middle.filled
    Sliders (S) are to the right of each path
        determins opacity of each path output
    Interactions
      Camera Input,
        put SW.camera.front icon in lower right corner of large square
        make lower right quadrant of large square tappable to switch front back cameras
        move camera.mix to canvas.mix
        remove SE.camera menu
      Album input
        in lower right corner of Input is a cirle + button
        tapping on Album Icon, Input or Paths will bring up picker
        switching from Af0b0 to anthing else with no prior album media will bring up picker
      Draw Input
        tapping on main input squwill bring up previous Canvas Draw [false real]
        tapping on Dr will bring up Canvs Draw Real
        tapping on Df will bring up Canvas Draw Fake
    Defaults are
        Dr0f3 Sa0b1
        CF0B0 Sa0b0// changing will turn on/off camera, Sa0b0 will also turn off camera
        AF0B0 Sa0b0
    Stub out _strip, _vertical, _shift,
    put SE.album.archive where where se.album
    Dragging layers still affects order
        double check how Dreamatic organizes pipeline
Canvas
    Draw
        Separate into two separate menus
            SW.canvas.real (use upper right color disk icon)
            SW.canvas.false (use upper left palette disk icon)
        remove the SW.canvas.draw
    Picker
        move P1 just below P0
        Move +-/KWZ button on left bottom
        Shorten right side to half right side width
            Make all slots empty
            make P0 and P1 dragable to a slot
            allow user to select a slot to edit
        Headline: allow user to edit text directly
        Add r o y g b i v tap circles around perimeter of disk
           just inside the boundary
           same size of current thumb
           black stroke around each circle
           add a small black letter inside
           tapping near cirle will add letter to palette
               and move the thumb over that cirle
        Home button default
            pal0 roygbivK
            pal1 wKZ
Menus, top down order of rearranged menu, ignoring beyond ...
  SW {
    canvas {
        real
        false
        picker
        repeat
    }
    cells { ... }
    plato { ... }
    layers
    archive
  }

Layers UI:
    shifting layers needs to start with a long press,
    with sequence from top to bottom (with top rendered last) Draw, Camera, Album.
    Missing radios buttons for routing.
Pencil actions
    Squeeze: same as tap on most recently used root button (SW or SE) can either show or hide.
    Double Tap:
        when canvas.real shown, then show canvas.false,
        when canvas.false shown, then canvas.real,
        when canvas.picker shown, then canvas.false.
canvas.picker
    menu icon use paintpalette.fill
    single letter short cuts
        add c(cyan), m(magenta)
        add on color disk
        add to swift text interpreter
    thumb white stroke should be larger than black circle strokes
    when tapping on a circle, should see it surrounds by while thumb stroke
    when moving thumb, white circle should be on top
    Palette slots
        add two more slots
        double tap on slot to replace currenly selected palette
    Tapping on Home
        shift ofs over 250 animation period
