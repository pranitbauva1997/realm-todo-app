module Pages.NotFoundTest exposing (..)

import Pages.NotFound as M
import Realm as R


main =
    R.test0 M.app init


anonymous : ( String, String )
anonymous =
    ( "NotFound", "anonymous" )


init : R.In -> R.TestFlags M.Config -> ( M.Model, Cmd (R.Msg M.Msg) )
init in_ ({ config, context } as test) =
    let
        id =
            ( "NotFound", test.id )

        ( m, c ) =
            M.app.init in_ test.config
    in
    if id == anonymous then
        ( m
        , R.result c
            [ R.TestFailed "base" "base not found"
            , R.TestDone
            ]
        )

    else
        ( m
        , R.result c
            [ R.TestFailed test.id "NotFoundTest: id not known", R.TestDone ]
        )
