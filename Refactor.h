
Dev has manually moved: field​, wave​, shapes​ to more.flo.h mic{...}
Have removed randomOn​. remove all references to randomOn in all code and shaders.
Refactor shapes transitioning old => new

    cone1On       => coneNum(x>0)
    cone2On       => coneSize(y>0)
    cone1Scale    => cone(x)
    cone2Scale    => cone(y)
    cone1Strength => cone(w)
    cone2Strength => cone(z)

    petal1On      => petal(x > 0)
    petal1Num     => petal(x)
    petal1Petalz  => petal(w)
    peta12On      => petal(y > 0)
    petal2Num     => petal(y) 
    petal2Petalz  => petal(z)

    petal1Spiralz   => spiral(x)
    petal1Strength  => spiral(w)
    petal1Spiralz   => spiral(y)
    petal1Strength  => spiral(z)

    columnOn       => column(x>0)
    columnNum      => column(x)
    columnRays     => column(y)
    columnStrength => column(z)

    circleOn   => cicle(x>0)
    circleRays => circle(x)
create a new LeafXyzw*, for new xyzw menu, where
    w slider is on bottom, aligned horizonaly with x slider.


Refactor out global variables from the Shapes menu and find out what happened to Petal. Here is the basic structure with hints about reassigment in comments

shapes (sym "snowflake",'procedural shape fields') {
    circular {
        cone (xyzw, x 0…40=5, y 0…40=5, z 50…400=100, w 50…400=100,
                 <> pipe.cell˚shape.circular)
        // was <> pipe.cell˚shape.cone, but unique for circular
    }
    zigular {
        cone    (xyzw, x 0…40=5, y 0…40=5, z 50…400=100, w 50…400=100,
                 <> pipe.cell˚shape.zigular)
        // was <> pipe.cell˚shape.cone, but unique for zigular
        // where z maps to pipe.cell˚shape.circle
    }
    simple {
        preset (seg, x 0_5=1,  <> pipe.cell˚shape.simple)
        // I think there other controls that got lost when translating from WinSky
    }
    petal { // where is this

        petal   (xyzw, x 0_14=1, y 0_7=1, z 0…50=0, w 0…50=0,
                 <> pipe.cell˚shape.petal)
        spiral  (xyzw, x -50…50=-50,  y -50…50=-50, z 400…1000=800,w 400…1000=800,
                 <> pipe.cell˚shape.spiral)
    }
}

DeepMuse Archive and Restore Recordings
    
