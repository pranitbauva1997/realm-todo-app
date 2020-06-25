module Actions exposing (..)

import Json.Encode as JE


s2 : String -> List ( String, JE.Value ) -> ( String, JE.Value )
s2 url params =
    ( url, JE.object params )


toggleToDo : Int -> ( String, JE.Value )
toggleToDo i =
    s2 "/toggle/" [ ( "index", JE.int i ) ]


addToDo : String -> Bool -> ( String, JE.Value )
addToDo title done =
    s2 "/add/"
        [ ( "title", JE.string title )
        , ( "done", JE.bool done )
        ]


deleteToDo : Int -> ( String, JE.Value )
deleteToDo i =
    s2 "/delete/" [ ( "index", JE.int i ) ]
