module Pages.Index exposing (..)

import Browser as B
import Element as E
import Element.Border as EB
import Element.Events as EE
import Element.Font as EF
import Element.Input as EI
import Emoji
import Json.Decode as JD
import Json.Encode as JE
import Realm as R
import Realm.Utils as RU exposing (edges)
import System as S


type alias Config =
    { list : List Item
    }


type alias Model =
    { list : List Item
    , hover : Maybe Int
    }


type Msg
    = Click Int
    | Delete Int
    | Hover Bool Int


todo : Int -> String -> Bool -> Item
todo index title done =
    { index = index, title = title, done = done }


config : JD.Decoder Config
config =
    JD.map Config
        (JD.field "list" (JD.list item))


configE : Config -> JE.Value
configE c =
    JE.object [ ( "list", JE.list itemE c.list ) ]


type alias Item =
    { index : Int
    , title : String
    , done : Bool
    }


itemE : Item -> JE.Value
itemE i =
    JE.object
        [ ( "index", JE.int i.index )
        , ( "title", JE.string i.title )
        , ( "done", JE.bool i.done )
        ]


item : JD.Decoder Item
item =
    JD.succeed Item
        |> R.field "index" JD.int
        |> R.field "title" JD.string
        |> R.field "done" JD.bool


init : R.In -> Config -> ( Model, Cmd (R.Msg Msg) )
init _ c =
    ( { list = c.list, hover = Maybe.Nothing }, Cmd.none )


update : R.In -> Msg -> Model -> ( Model, Cmd (R.Msg Msg) )
update _ msg m =
    case msg of
        Click idx ->
            let
                modified =
                    RU.mapIth idx (\i -> { i | done = not i.done }) m.list
            in
            ( { m | list = modified }, Cmd.none )

        Delete idx ->
            ( { m | list = RU.deleteIth idx m.list }, Cmd.none )

        Hover open idx ->
            if open then
                ( { m | hover = Just idx }, Cmd.none )

            else
                ( { m | hover = Nothing }, Cmd.none )


document : R.In -> Model -> B.Document (R.Msg Msg)
document in_ m =
    view m (min 500 (in_.width - 50))
        |> E.map R.Msg
        |> R.document in_


view : Model -> Int -> E.Element Msg
view m width =
    E.column [ E.width E.fill, E.height E.fill ]
        [ heading
        , RU.yesno (List.isEmpty m.list) empty (list m) width
        , addTodoView width
        ]


addTodoView : Int -> E.Element Msg
addTodoView width =
    E.column
        [ E.centerX
        , E.width (E.px width)
        , EB.widthEach { edges | top = 20 }
        , EB.color S.white
        ]
        [ EI.button
            [ E.centerX
            ]
            { onPress = Nothing
            , label = E.text Emoji.plus
            }
        ]


empty : Int -> E.Element Msg
empty width =
    RU.text
        [ E.centerX
        , E.width (E.px width)
        , EB.width 1
        , EB.rounded 2
        , EB.color S.gray5
        , E.padding 10
        , EF.center
        ]
        "No ToDos, yay!"


heading : E.Element Msg
heading =
    RU.text [ E.centerX, EF.size 24, EF.color S.gray2, E.padding 20 ] "todos"


footer : List Item -> E.Element Msg
footer lst =
    let
        filtered =
            List.filter .done lst

        wrapper =
            RU.text [ E.padding 10, EF.color S.gray3, EF.size 14 ]

        title =
            case List.length filtered of
                0 ->
                    E.none

                1 ->
                    "1 item left"
                        |> wrapper

                _ ->
                    String.fromInt (List.length filtered)
                        ++ " items left"
                        |> wrapper
    in
    title


itemView : Model -> Int -> Item -> E.Element Msg
itemView m idx i =
    E.row
        [ E.padding 10
        , EB.widthEach { edges | bottom = 1 }
        , EB.color S.gray5
        , E.width E.fill
        , E.spacing 5
        , RU.onClick (Click idx)
        , RU.onDoubleClick (Click idx)
        , EE.onMouseEnter (Hover True idx)
        , EE.onMouseLeave (Hover False idx)
        , E.pointer
        ]
        [ RU.text [ E.alignTop ] <| RU.yesno i.done Emoji.public Emoji.private
        , E.paragraph [] [ E.text i.title ]
        , RU.iff (m.hover == Just idx) <|
            E.el [ E.alignRight, RU.onClick (Delete idx), EF.size 12 ]
                (E.text Emoji.cross)
        ]


list : Model -> Int -> E.Element Msg
list m width =
    let
        filtered =
            List.filter .done m.list

        bottom =
            case filtered of
                [] ->
                    0

                _ ->
                    1
    in
    E.column
        [ E.centerX
        , E.width (E.px width)
        , EB.widthEach { edges | left = 1, top = 1, right = 1, bottom = bottom }
        , EB.rounded 2
        , EB.color S.gray5
        ]
        [ E.column
            [ E.height (E.fill |> E.maximum 300 |> E.minimum 30)
            , E.scrollbarY
            , E.width E.fill
            , EB.color S.gray5
            ]
            (List.indexedMap (itemView m) m.list)
        , footer m.list
        ]


subscriptions : R.In -> Model -> Sub (R.Msg Msg)
subscriptions _ _ =
    Sub.none


app : R.App Config Model Msg
app =
    R.App config init update subscriptions document


main =
    R.app app
