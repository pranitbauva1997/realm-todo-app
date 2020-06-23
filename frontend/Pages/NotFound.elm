module Pages.NotFound exposing (..)

import Browser as B
import Element as E
import Element.Font as EF
import Json.Decode as JD
import Realm as R
import Realm.Utils as RU


type alias Config =
    { message : String
    }


type alias Model =
    { config : Config
    }


type Msg
    = NoOp


init : R.In -> Config -> ( Model, Cmd (R.Msg Msg) )
init _ c =
    ( { config = c }, Cmd.none )


update : R.In -> Msg -> Model -> ( Model, Cmd (R.Msg Msg) )
update _ msg m =
    case msg of
        NoOp ->
            ( m, Cmd.none )


document : R.In -> Model -> B.Document (R.Msg Msg)
document in_ m =
    view in_ m
        |> R.document in_


subscriptions : R.In -> Model -> Sub (R.Msg Msg)
subscriptions _ _ =
    Sub.none


app : R.App Config Model Msg
app =
    R.App config init update subscriptions document


view : R.In -> Model -> E.Element (R.Msg Msg)
view in_ m =
    let
        maxWidth =
            RU.yesno (in_.width > 750) 750 in_.width

        title =
            "Page not found: "
                ++ " ("
                ++ m.config.message
                ++ ")"
    in
    E.column [ E.spacing 20, E.padding 20, E.width E.fill ] <|
        [ E.image [ E.width (E.px maxWidth), E.centerX, RU.title title ]
            { src = "/static/404.png", description = "Page Not Found Image" }
        , E.paragraph [ EF.size 10, EF.center ]
            [ E.text "Illustration by "
            , E.link []
                { url = "https://icons8.com/ouch/illustration/fogg-page-not-found-1"
                , label = E.text "Marina Fedoseenko"
                }
            ]
        ]


config : JD.Decoder Config
config =
    JD.succeed Config
        |> R.field "message" JD.string


main =
    R.app app
