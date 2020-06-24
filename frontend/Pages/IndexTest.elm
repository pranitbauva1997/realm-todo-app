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


toggleToDo : ( String, String )
toggleToDo =
    ( "Index", "toggleToDo" )


threeNotDone : ( String, String )
threeNotDone =
    ( "Index", "threeNotDone" )


firstDone : ( String, String )
firstDone =
    ( "Index", "firstDone" )


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
    (if id == threeNotDone then
        [ RU.match "three not done"
            [ M.todo 1 "hello one" False
            , M.todo 2 "hello two" False
            , M.todo 3 "hello three" False
            ]
            test.config.list
        ]

     else if id == firstDone then
        [ RU.match "first done"
            [ M.todo 1 "hello one" True
            , M.todo 2 "hello two" False
            , M.todo 3 "hello three" False
            ]
            test.config.list
        ]

     else if id == emptyList then
        [ RU.match "no todos" [] test.config.list ]

     else if id == singleToDo then
        [ RU.match "single todo"
            [ M.todo 1 "Hello" False ]
            test.config.list
        ]

     else if id == toggleToDo then
        [ RU.match "toggling todo"
            [ M.todo 1 "Hello" True ]
            test.config.list
        ]

     else
        [ R.TestFailed test.id "IndexTest: id not known" ]
    )
        |> f
