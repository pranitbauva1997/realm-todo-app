module Test exposing (main)

import Actions
import Json.Encode as JE
import Realm.Test as RT
import Routes
import ToDoTest as ToDo


main =
    RT.app { tests = tests, title = "Realm ToDo App" }


tests : List RT.Test
tests =
    let
        context =
            [ ( "name", JE.string "Realm Tutorial" ) ]

        f : String -> List RT.Step -> RT.Test
        f id steps =
            { id = id, context = context, steps = steps }

        t =
            [ f "index" index
            , f "resetDB" resetDB
            ]
    in
    t



--index : List RT.Step
--index =
--    [ RT.Navigate ToDo.threeNotDone Routes.clearTodos
--    , RT.Navigate ToDo.threeNotDone Routes.index
--    , RT.SubmitForm ToDo.firstDone (Actions.toggleToDo 0)
--    , RT.Navigate ToDo.firstDone Routes.index
--    , RT.SubmitForm ToDo.threeNotDone (Actions.toggleToDo 0)
--    , RT.Navigate ToDo.threeNotDone Routes.index
--    ]


index : List RT.Step
index =
    [ RT.Navigate ToDo.emptyList Routes.emptyToDo
    , RT.SubmitForm ToDo.singleToDo (Actions.addToDo "Hello" False)
    ]


resetDB : List RT.Step
resetDB =
    [ RT.Navigate ToDo.emptyList Routes.emptyToDo ]
