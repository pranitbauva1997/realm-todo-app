module Actions exposing (..)

import Json.Encode as JE


s2 : String -> List ( String, JE.Value ) -> ( String, JE.Value )
s2 url params =
    ( url, JE.object params )


toggleToDo : Int -> ( String, JE.Value )
toggleToDo i =
    s2 "/api/toggle-todo/" [ ( "index", JE.int i ) ]
