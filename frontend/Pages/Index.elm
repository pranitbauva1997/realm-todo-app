module Pages.Index exposing (Config, main)

import Browser as B
import Element as E
import Element.Events as EE
import Element.Font as EF
import Json.Decode as JD
import Realm as R


main =
    R.app app


app : R.App Config Config ()
app =
    R.App config R.init0 R.update0 R.sub0 document


type alias Config =
    { message : String
    , count : Int
    }


view : Config -> E.Element (R.Msg ())
view c =
    E.column [ E.centerX, E.centerY, E.spacing 20 ]
        [ E.el [ E.centerX, EF.italic ]
            (E.text "Hello Elm")
        , E.text ("Message from server: " ++ c.message)
        , E.row [ E.spacing 10, E.alignRight ]
            [ E.text ("Count: " ++ String.fromInt c.count)
            , E.link []
                { url = "/increment/"
                , label = E.text "Go Up"
                }
            ]
        ]


document : R.In -> Config -> B.Document (R.Msg ())
document in_ =
    view >> R.document in_


config : JD.Decoder Config
config =
    JD.map2 Config
        (JD.field "message" JD.string)
        (JD.field "count" JD.int)
