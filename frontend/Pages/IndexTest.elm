module Pages.IndexTest exposing (..)

import Pages.Index as M
import Realm as R
import Realm.Utils as RU


main =
    R.test0 M.app init


emptyList : ( String, String )
emptyList =
    ( "Index", "emptyList" )


singleToDo : ( String, String )
singleToDo =
    ( "Index", "singleToDo" )


deleteToDo : ( String, String )
deleteToDo =
    ( "Index", "deleteToDo" )


twoToDos : ( String, String )
twoToDos =
    ( "Index", "twoToDos" )


toggleToDo : ( String, String )
toggleToDo =
    ( "Index", "toggleToDo" )


init : R.In -> R.TestFlags M.Config -> ( M.Model, Cmd (R.Msg M.Msg) )
init in_ test =
    let
        id =
            ( "Index", test.id )

        ( m, c ) =
            M.app.init in_ test.config

        f : List R.TestResult -> ( M.Model, Cmd (R.Msg M.Msg) )
        f l =
            ( m, R.result c (l ++ [ R.TestDone ]) )
    in
    (if id == emptyList then
        [ RU.match "no todos" [] test.config.list ]

     else if id == singleToDo then
        [ RU.match "single todo"
            [ M.todo 1 "Hello" False ]
            test.config.list
        ]

     else if id == deleteToDo then
        [ RU.match "single todo"
            [ M.todo 1 "Hello" False ]
            test.config.list
        ]

     else if id == twoToDos then
        [ RU.match "two todos"
            [ M.todo 1 "Hello" False
            , M.todo 2 "World" False
            ]
            test.config.list
        ]

     else if id == toggleToDo then
        [ RU.match "toggling todo"
            [ M.todo 1 "Hello" False
            , M.todo 2 "World" True
            ]
            test.config.list
        ]

     else
        [ R.TestFailed test.id "IndexTest: id not known" ]
    )
        |> f
