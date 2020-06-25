module Actions exposing (..)

import Json.Encode as JE


s2 : String -> List ( String, JE.Value ) -> ( String, JE.Value )
s2 url params =
    ( url, JE.object params )


toggleToDo : Int -> ( String, JE.Value )
toggleToDo i =
    s2 "/api/toggle-todo/" [ ( "index", JE.int i ) ]


addToDo : String -> Bool -> ( String, JE.Value )
addToDo title done =
    s2 "/add-todo/"
        [ ( "title", JE.string title )
        , ( "done", JE.bool done )
        ]


deleteToDo : Int -> ( String, JE.Value )
deleteToDo i =
    s2 "/api/delete-todo/" [ ( "index", JE.int i ) ]
