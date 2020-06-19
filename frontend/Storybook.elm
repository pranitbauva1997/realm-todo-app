module Storybook exposing (main)

import Json.Encode as JE
import Pages.Index as Index
import Realm.Storybook as RSB exposing (Story)


main =
    RSB.app { stories = stories, title = "Realm-Starter" }


stories : List ( String, List Story )
stories =
    [ ( "Index"
      , [ index "count_42"
            "Count = 42"
            { message = "hello world", count = 42 }
        , index "big_message"
            "Big Message"
            { message = "hello world, its really nice to meet you!"
            , count = 2
            }
        ]
      )
    ]


index : String -> String -> Index.Config -> Story
index id title c =
    { id = id
    , title = title
    , pageTitle = title
    , elmId = "Pages.Index"
    , config =
        JE.object
            [ ( "count", JE.int c.count ), ( "message", JE.string c.message ) ]
    }
