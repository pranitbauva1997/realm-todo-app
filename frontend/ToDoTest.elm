module ToDoTest exposing (..)

import Pages.Index as M
import Realm as R
import Realm.Utils as RU


main =
    R.test0 M.app init


threeNotDone : ( String, String )
threeNotDone =
    ( "ToDo", "threeNotDone" )


firstDone : ( String, String )
firstDone =
    ( "ToDo", "firstDone" )


init : R.In -> R.TestFlags M.Config -> ( M.Model, Cmd (R.Msg M.Msg) )
init in_ test =
    let
        id =
            ( "ToDo", test.id )

        ( m, c ) =
            M.app.init in_ test.config

        f : List R.TestResult -> ( M.Model, Cmd (R.Msg M.Msg) )
        f l =
            ( m, R.result c (l ++ [ R.TestDone ]) )
    in
    (if id == threeNotDone then
        [ RU.match "three not done"
            [ M.todo "hello one" False
            , M.todo "hello two" False
            , M.todo "hello three" False
            ]
            test.config.list
        ]

     else if id == firstDone then
        [ RU.match "first done"
            [ M.todo "hello one" True
            , M.todo "hello two" False
            , M.todo "hello three" False
            ]
            test.config.list
        ]

     else
        [ R.TestFailed test.id "IndexTest: id not known" ]
    )
        |> f