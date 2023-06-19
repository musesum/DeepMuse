
Goals
    everyone is a VJ performing over popular music
    shared performance between devices
    touch on menu and canvas
    synchronize performance with static streams
        spotify, apple music, etc
        extend to live broadcast of major events
Notes
    in flo.par, the order of expr is imporant
    
    expr   ≈ (scalar | exprOp | name | quote | comment)+
    in  exprBad1  ≈ (exprOp |scalar | name | quote | comment)+
    
        a(%2~1) won't part `~1` as the `%` is interpreted as an exprOp
        
    in  exprBad2  ≈ ( name | exprOp |scalar |quote | comment)+
    
        b(x in 0…2) will interpret in as a name instead of an exprOp
