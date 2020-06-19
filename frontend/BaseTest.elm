module Widgets.BaseTest exposing (..)

import Json.Decode as JD
import Json.Encode as JE
import Realm as R
import Realm.Utils as RU
import Widgets.Base as M


anonymous : String -> M.Config -> JE.Value -> R.TestResult
anonymous id config _ =
    case config.name of
        Just name ->
            R.TestFailed id <| "expected anonymous, found: " ++ name

        Nothing ->
            R.TestPassed id


loggedIn : String -> M.Config -> JE.Value -> R.TestResult
loggedIn id config ctx =
    case ( config.name, JD.decodeValue (JD.field "name" JD.string) ctx ) of
        ( Just name, Ok expected ) ->
            if name == expected then
                R.TestPassed id

            else
                R.TestFailed id <| "expected: " ++ expected ++ ", found: " ++ name

        ( Just _, Err e ) ->
            R.TestFailed id <| "name not set in context: " ++ Debug.toString e

        ( Nothing, _ ) ->
            R.TestFailed id "expected logged in, found anonymous"


dhruv : String -> M.Config -> R.TestResult
dhruv id config =
    case config.name of
        Just "Super Commando Dhruv" ->
            R.TestPassed id

        Just f ->
            R.TestFailed id <| "Expected Super Commando Dhruv, found: " ++ f

        Nothing ->
            R.TestFailed id "expected logged in, found anonymous"


hasNotes : String -> String -> M.Config -> R.TestResult
hasNotes title id config =
    RU.match id
        [ { id = "amitu/notes"
          , public = False
          , title =
                { original = title
                , rendered = RU.Rendered title
                }
          , url = "/amitu/notes/"
          }
        ]
        config.inLibrary
