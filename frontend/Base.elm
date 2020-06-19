module Widgets.Base exposing (Config, Model, Msg(..), authenticate, config, configE, default, dialogOpen, hasModal, init, isLoggedIn, loaded, localE, naked, subscriptions, switcher, update, view)

import Animation
import Animation.Messenger
import Api
import Browser.Dom as Dom
import Browser.Events as BE
import Common.Content as Content
import Common.System as CS exposing (edges)
import Common.Types as CT
import Dict exposing (Dict)
import Element as E
import Element.Background as Bg
import Element.Border as EB
import Element.Events as EE
import Element.Font as EF
import Element.Input as EI
import Element.Region as ER
import Emoji
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as JD
import Json.Encode as JE
import Library as L
import Library.Dialog as Dialog
import Realm as R
import Realm.Ports as RP
import Realm.Utils as RU
import Routes
import System as S
import Task
import Time
import Time.Distance as TD
import Url


type alias Config =
    { name : Maybe String
    , local : Maybe Local
    , build : String
    , tracks : List Content.ContentMeta
    , inLibrary : List Content.ContentMeta
    , currentTrack : Maybe String
    , recent : List Content.ContentMeta
    , likes : List Content.ContentMeta
    }


default : Config
default =
    { name = Nothing
    , local = Nothing
    , build = "build"
    , tracks = []
    , inLibrary = []
    , currentTrack = Nothing
    , recent = []
    , likes = []
    }


type alias Local =
    { conflicts : Int
    , lastSyncOn : Maybe Int
    , now : Int
    , hasLocalChanges : Bool
    }


type alias Model =
    { config : Config
    , onNameHovering : Bool
    , onName : Animation.Messenger.State Msg
    , authenticating : Maybe Authenticating
    , unloading : Bool
    , switcher : Switcher
    , showHelp : Bool
    , qn : QuickNote
    , recent : Switcher
    , likes : Switcher
    , dialogHeight : Maybe Int
    }


type alias QuickNote =
    { visible : Bool
    , field : RU.Field
    }


type Focus
    = FUsername
    | FPassword
    | FOTP
    | FEmail
    | FName


type alias Switcher =
    { visible : Bool
    , current : Int
    }


type alias Authenticating =
    { title : String
    , token : String
    , state : AuthState
    }


type AuthState
    = ASLogin { username : RU.Field, password : RU.Field }
    | ASOTPLogin { username : RU.Field }
    | ASEnterOTP { username : String, signed : String, otp : RU.Field }
    | ASResetPassword
        { password : RU.Field
        , show : Bool
        , signed : String
        , otp : RU.Field
        }
    | ASCreate Info


type alias Info =
    { email : RU.Field
    , name : RU.Field
    , password : RU.Field
    , show : Bool
    , otp : RU.Field
    , signed : Maybe String
    }


type Msg
    = Hover Bool
    | HoverDone
    | Animate Animation.Msg
    | ClosePopup
    | OnUsername String
    | OnName String
    | OnPassword String
    | OnOTP String
    | OnEmail String
    | SwitchToOTP
    | SwitchToLogin
    | SwitchToCreate
    | OTPDone
    | Submit
    | SignIn
    | SignUp
    | OnError2 (Dict String String)
    | AuthDone String Bool
    | OnSuccess
    | OnOTPSent String
    | ToggleShowPassword
    | OnCreateOTPSent String
    | OnUnloading Bool
    | Reload
    | NoOp
    | GoToCreateUser
    | ShortCut ShortCut
    | Focus Focus Bool
    | QNText String
    | QNSave
    | QNSaved
    | GotDialogHeight (Result Dom.Error Int)


type ShortCut
    = KShowSwitcher
    | KHideSwitcher
    | KHideRecent
    | KShowRecent
    | KHideLikes
    | KShowLikes
    | KShowHelp
    | KHideHelp
    | KSwitcherNext
    | KSwitcherPrev
    | KSwitcherSelect Int
    | KRecentNext
    | KRecentPrev
    | KRecentSelect Int
    | KLikesNext
    | KLikesPrev
    | KLikesSelect Int
    | KGoToSync
    | KQuickNote
    | KHideQN


emptyQN : String -> RU.Field
emptyQN s =
    { value = "-- markdown:\n\n" ++ s
    , error = Nothing
    , edited = False
    , focused = False
    }


init : R.In -> Config -> ( Model, Cmd Msg )
init in_ c =
    ( { config = { c | recent = List.filter (\x -> x.url /= in_.url.path) c.recent }
      , onNameHovering = False
      , onName = Animation.style [ Animation.opacity 0 ]
      , authenticating = Nothing
      , unloading = False
      , switcher = { visible = False, current = 0 }
      , recent = { visible = False, current = 0 }
      , likes = { visible = False, current = 0 }
      , showHelp = False
      , qn =
            { visible =
                in_.url.query
                    |> Maybe.map (String.contains "qn=true")
                    |> Maybe.withDefault False
            , field =
                in_.url.fragment
                    |> Maybe.andThen Url.percentDecode
                    |> Maybe.withDefault ""
                    |> emptyQN
            }
      , dialogHeight = Nothing
      }
    , Cmd.none
    )


loaded : Model -> Model
loaded m =
    { m | unloading = False }


hasModal : Model -> Bool
hasModal m =
    m.qn.visible || m.switcher.visible || m.showHelp


resetDialogs : Model -> Model
resetDialogs m =
    let
        s1 =
            m.switcher

        s2 =
            { s1 | visible = False }

        r1 =
            m.recent

        r2 =
            { r1 | visible = False }

        l1 =
            m.likes

        l2 =
            { l1 | visible = False }

        q1 =
            m.qn

        q2 =
            { q1 | visible = False }
    in
    { m | switcher = s2, recent = r2, likes = l2, showHelp = False, qn = q2 }


update : R.In -> Msg -> Model -> ( Model, Cmd (R.Msg Msg) )
update in_ msg model =
    let
        onSwitcher : (Switcher -> Switcher) -> Model -> ( Model, Cmd (R.Msg Msg) )
        onSwitcher f m =
            ( { m | switcher = f m.switcher }, Cmd.none )

        onRecent : (Switcher -> Switcher) -> Model -> ( Model, Cmd (R.Msg Msg) )
        onRecent f m =
            ( { m | recent = f m.recent }, Cmd.none )

        onLikes : (Switcher -> Switcher) -> Model -> ( Model, Cmd (R.Msg Msg) )
        onLikes f m =
            ( { m | likes = f m.likes }, Cmd.none )

        onStyle :
            Model
            ->
                (Animation.Messenger.State Msg
                 -> ( Animation.Messenger.State Msg, Cmd Msg )
                )
            -> ( Model, Cmd (R.Msg Msg) )
        onStyle m fn =
            fn m.onName
                |> Tuple.mapFirst (\t -> { m | onName = t })
                |> Tuple.mapSecond (Cmd.map R.Msg)

        onAuth : (AuthState -> AuthState) -> Model -> Model
        onAuth f m =
            case m.authenticating of
                Just auth ->
                    let
                        auth2 =
                            { auth | state = f auth.state }
                    in
                    { m | authenticating = Just auth2 }

                Nothing ->
                    m

        onLogin :
            ({ username : RU.Field, password : RU.Field }
             -> { username : RU.Field, password : RU.Field }
            )
            -> Model
            -> Model
        onLogin f =
            onAuth
                (\a ->
                    case a of
                        ASLogin d ->
                            ASLogin (f d)

                        _ ->
                            a
                )

        onResetPassword :
            ({ password : RU.Field, show : Bool, signed : String, otp : RU.Field }
             -> { password : RU.Field, show : Bool, signed : String, otp : RU.Field }
            )
            -> Model
            -> Model
        onResetPassword f =
            onAuth
                (\a ->
                    case a of
                        ASResetPassword d ->
                            ASResetPassword (f d)

                        _ ->
                            a
                )

        onOTPLogin :
            ({ username : RU.Field }
             -> { username : RU.Field }
            )
            -> Model
            -> Model
        onOTPLogin f =
            onAuth
                (\a ->
                    case a of
                        ASOTPLogin d ->
                            ASOTPLogin (f d)

                        _ ->
                            a
                )

        onCreate : (Info -> Info) -> Model -> Model
        onCreate f =
            onAuth
                (\a ->
                    case a of
                        ASCreate d ->
                            ASCreate (f d)

                        _ ->
                            a
                )

        onOTP :
            ({ otp : RU.Field, signed : String, username : String }
             -> { otp : RU.Field, signed : String, username : String }
            )
            -> Model
            -> Model
        onOTP f =
            onAuth
                (\a ->
                    case a of
                        ASEnterOTP d ->
                            ASEnterOTP (f d)

                        _ ->
                            a
                )

        field : RU.Field -> String -> RU.Field
        field f v =
            if String.length v == 0 && f.edited then
                { f | value = v, error = Just "Field is required", edited = True }

            else if String.length v > 100 then
                { f | value = v, error = Just "Max length 100", edited = True }

            else
                { f | value = v, error = Nothing, edited = True }

        nonify : Model -> ( Model, Cmd (R.Msg msg) )
        nonify m =
            ( m, Cmd.none )

        onAuth2 : (AuthState -> AuthState) -> ( Model, Cmd (R.Msg msg) )
        onAuth2 f =
            model |> onAuth f |> nonify

        internal =
            "--internal-- "

        final : Authenticating -> Bool -> () -> Msg
        final auth goToAuth =
            if auth.token == internal then
                always (RU.yesno goToAuth GoToCreateUser Reload)

            else
                always (AuthDone auth.token True)

        onQuick : (QuickNote -> QuickNote) -> Model -> Model
        onQuick f m =
            { m | qn = f m.qn }

        onQuickField : (RU.Field -> RU.Field) -> Model -> Model
        onQuickField f =
            onQuick (\q -> { q | field = f q.field })

        currentProject =
            let
                c =
                    Maybe.withDefault "" model.config.currentTrack
            in
            List.partition (\t -> t.id < c) model.config.tracks
                |> Tuple.first
                |> List.length
    in
    case msg of
        GotDialogHeight (Ok h) ->
            ( { model | dialogHeight = Just h }, Cmd.none )

        GotDialogHeight (Err _) ->
            ( model, Cmd.none )

        QNSave ->
            ( model
            , case List.head model.config.tracks of
                Just first ->
                    Api.createQuickNote (CT.Body model.qn.field.value)
                        (CT.ModuleID (first.id ++ "/inbox"))
                        |> R.api (always QNSaved) OnError2

                Nothing ->
                    Cmd.none
            )

        QNSaved ->
            let
                inbox =
                    List.head model.config.tracks
                        |> Maybe.map .id
                        |> Maybe.map (\id -> "/" ++ id ++ "/inbox/")
            in
            ( onQuick (\q -> { q | visible = False, field = emptyQN "" }) model
            , if inbox == Just in_.url.path then
                R.navigate in_.url.path

              else
                Cmd.none
            )

        QNText v ->
            if String.isEmpty v then
                onQuickField (\f -> { f | value = v, error = Just "This is required." })
                    model
                    |> nonify

            else
                onQuickField (\f -> { f | value = v, error = Nothing }) model
                    |> nonify

        ShortCut KHideQN ->
            onQuick (\q -> { q | visible = False }) model |> nonify

        ShortCut KQuickNote ->
            let
                m =
                    resetDialogs model
            in
            if List.isEmpty m.config.tracks then
                ( m, Cmd.none )

            else
                onQuick (\q -> { q | visible = not q.visible }) m
                    |> nonify

        ShortCut KGoToSync ->
            ( model, R.navigate "/sync/" )

        ShortCut KShowHelp ->
            let
                m =
                    resetDialogs model
            in
            ( { m | showHelp = True }
            , Cmd.batch
                [ RP.disableScrolling ()
                , Task.attempt (GotDialogHeight >> R.Msg) Dialog.getDialogHeight
                ]
            )

        ShortCut KHideHelp ->
            let
                m =
                    resetDialogs model
            in
            ( { m | showHelp = False }, RP.enableScrolling () )

        ShortCut KShowSwitcher ->
            onSwitcher (\s -> { s | visible = True, current = currentProject })
                (resetDialogs model)
                |> Tuple.mapSecond
                    (always
                        (Cmd.batch
                            [ RP.disableScrolling ()
                            , Task.attempt (GotDialogHeight >> R.Msg) Dialog.getDialogHeight
                            ]
                        )
                    )

        ShortCut KHideSwitcher ->
            onSwitcher (\s -> { s | visible = False }) (resetDialogs model)
                |> Tuple.mapSecond (always (RP.enableScrolling ()))

        ShortCut KShowRecent ->
            onRecent (\s -> { s | visible = True, current = 0 })
                (resetDialogs model)
                |> Tuple.mapSecond
                    (always
                        (Cmd.batch
                            [ RP.disableScrolling ()
                            , Task.attempt (GotDialogHeight >> R.Msg)
                                Dialog.getDialogHeight
                            ]
                        )
                    )

        ShortCut KHideRecent ->
            onRecent (\s -> { s | visible = False }) { model | showHelp = False }
                |> Tuple.mapSecond (always (RP.enableScrolling ()))

        ShortCut KHideLikes ->
            onLikes (\s -> { s | visible = False }) { model | showHelp = False }
                |> Tuple.mapSecond (always (RP.enableScrolling ()))

        ShortCut KShowLikes ->
            onLikes (\s -> { s | visible = True, current = 0 })
                (resetDialogs model)
                |> Tuple.mapSecond
                    (always
                        (Cmd.batch
                            [ RP.disableScrolling ()
                            , Task.attempt (GotDialogHeight >> R.Msg)
                                Dialog.getDialogHeight
                            ]
                        )
                    )

        ShortCut KSwitcherNext ->
            onSwitcher
                (\s ->
                    { s
                        | current =
                            modBy (List.length model.config.tracks)
                                (s.current + 1)
                    }
                )
                model

        ShortCut KSwitcherPrev ->
            onSwitcher
                (\s ->
                    { s
                        | current =
                            modBy (List.length model.config.tracks)
                                (s.current - 1)
                    }
                )
                model

        ShortCut (KSwitcherSelect i) ->
            model.config.tracks
                |> RU.lGet i
                |> Maybe.map (.url >> R.navigate)
                |> Maybe.withDefault Cmd.none
                |> (\t -> Cmd.batch [ RP.enableScrolling (), t ])
                |> Tuple.pair model

        ShortCut KRecentNext ->
            onRecent
                (\s ->
                    { s
                        | current =
                            modBy (List.length model.config.recent)
                                (s.current + 1)
                    }
                )
                model

        ShortCut KRecentPrev ->
            onRecent
                (\s ->
                    { s
                        | current =
                            modBy (List.length model.config.recent)
                                (s.current - 1)
                    }
                )
                model

        ShortCut (KRecentSelect i) ->
            model.config.recent
                |> RU.lGet i
                |> Maybe.map (.url >> R.navigate)
                |> Maybe.withDefault Cmd.none
                |> (\t -> Cmd.batch [ RP.enableScrolling (), t ])
                |> Tuple.pair model

        ShortCut KLikesNext ->
            onLikes
                (\s ->
                    { s
                        | current =
                            modBy (List.length model.config.likes)
                                (s.current + 1)
                    }
                )
                model

        ShortCut KLikesPrev ->
            onLikes
                (\s ->
                    { s
                        | current =
                            modBy (List.length model.config.likes)
                                (s.current - 1)
                    }
                )
                model

        ShortCut (KLikesSelect i) ->
            model.config.likes
                |> RU.lGet i
                |> Maybe.map (.url >> R.navigate)
                |> Maybe.withDefault Cmd.none
                |> (\t -> Cmd.batch [ RP.enableScrolling (), t ])
                |> Tuple.pair model

        GoToCreateUser ->
            ( model, R.navigate (Routes.createUsername False) )

        Reload ->
            ( model, R.refresh )

        SignIn ->
            ( authenticate "" internal model, Cmd.none )

        SignUp ->
            ( { model
                | authenticating =
                    Just
                        { title = ""
                        , token = internal
                        , state =
                            ASCreate
                                { email = RU.emptyField
                                , name = RU.emptyField
                                , password = RU.emptyField
                                , show = False
                                , signed = Nothing
                                , otp = RU.emptyField
                                }
                        }
              }
            , Cmd.none
            )

        Hover v ->
            ( { model
                | onName =
                    Animation.interrupt
                        (if v then
                            [ Animation.to [ Animation.opacity 1 ] ]

                         else
                            [ Animation.to [ Animation.opacity 0 ]
                            , Animation.Messenger.send HoverDone
                            ]
                        )
                        model.onName
                , onNameHovering = True
              }
            , Cmd.none
            )

        HoverDone ->
            ( { model | onNameHovering = False }, Cmd.none )

        Animate animMsg ->
            onStyle model (Animation.Messenger.update animMsg)

        ClosePopup ->
            ( { model | authenticating = Nothing }
            , RU.message (R.Msg (AuthDone "" False))
            )

        AuthDone _ _ ->
            -- this message should be captured by caller
            ( { model | authenticating = Nothing }, Cmd.none )

        OnSuccess ->
            case model.authenticating of
                Just auth ->
                    case auth.state of
                        ASLogin _ ->
                            ( { model | authenticating = Nothing }
                            , RU.message (final auth False ()) |> Cmd.map R.Msg
                            )

                        _ ->
                            ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        OnOTPSent signed ->
            onAuth2
                (\s ->
                    case s of
                        ASOTPLogin d ->
                            ASEnterOTP
                                { username = d.username.value
                                , otp = RU.emptyField
                                , signed = signed
                                }

                        _ ->
                            s
                )

        OnCreateOTPSent signed ->
            ( onCreate (\d -> { d | signed = Just signed }) model, Cmd.none )

        OTPDone ->
            onAuth2
                (\s ->
                    case s of
                        ASEnterOTP e ->
                            ASResetPassword
                                { show = False
                                , password = RU.emptyField
                                , otp = e.otp
                                , signed = e.signed
                                }

                        _ ->
                            Debug.todo "impossible"
                )

        ToggleShowPassword ->
            onAuth2
                (\s ->
                    case s of
                        ASCreate d ->
                            ASCreate { d | show = not d.show }

                        ASResetPassword d ->
                            ASResetPassword { d | show = not d.show }

                        _ ->
                            s
                )

        NoOp ->
            ( model, Cmd.none )

        Submit ->
            case model.authenticating of
                Just auth ->
                    case auth.state of
                        ASLogin d ->
                            ( model
                            , Api.login (CT.UsernameOrEmail d.username.value)
                                (CT.Password d.password.value)
                                |> R.api (always OnSuccess) OnError2
                            )

                        ASOTPLogin d ->
                            ( model
                            , Api.sendOTP (CT.UsernameOrEmail d.username.value)
                                |> R.api OnOTPSent OnError2
                            )

                        ASEnterOTP d ->
                            ( model
                            , Api.verifyOTP (CT.UsernameOrEmail d.username)
                                (CT.OTP d.otp.value)
                                d.signed
                                |> R.api (always OTPDone) OnError2
                            )

                        ASResetPassword d ->
                            ( model
                            , Api.resetPassword (CT.Password d.password.value)
                                (CT.OTP d.otp.value)
                                d.signed
                                |> R.api (final auth False) OnError2
                            )

                        ASCreate d ->
                            ( model
                            , case d.signed of
                                Nothing ->
                                    Api.createAccount (CT.Email d.email.value)
                                        (CT.Name d.name.value)
                                        (CT.Password d.password.value)
                                        |> R.api OnCreateOTPSent OnError2

                                Just signed ->
                                    Api.createAccountWithOTP (CT.Email d.email.value)
                                        (CT.Name d.name.value)
                                        (CT.Password d.password.value)
                                        (CT.OTP d.otp.value)
                                        signed
                                        |> R.api (final auth True) OnError2
                            )

                Nothing ->
                    ( model, Cmd.none )

        OnError2 d ->
            let
                username =
                    \a -> { a | username = RU.withError d "username" a.username }

                email =
                    \a -> { a | email = RU.withError d "email" a.email }

                otp =
                    \a -> { a | otp = RU.withError d "otp" a.otp }

                name =
                    \a -> { a | name = RU.withError d "name" a.name }

                password =
                    \a -> { a | password = RU.withError d "password" a.password }

                qn =
                    \a ->
                        { a
                            | field =
                                a.field
                                    |> RU.withError d "id"
                                    |> RU.withError d "text"
                        }
            in
            model
                |> onLogin username
                |> onLogin password
                |> onOTPLogin username
                |> onOTP otp
                |> onResetPassword password
                |> onCreate email
                |> onCreate name
                |> onCreate password
                |> onCreate otp
                |> onQuick qn
                |> nonify

        OnUsername u ->
            let
                f =
                    \a -> { a | username = field a.username u }
            in
            model
                |> onLogin f
                |> onOTPLogin f
                |> nonify

        OnOTP otp ->
            let
                f =
                    \a -> { a | otp = field a.otp otp }
            in
            model
                |> onOTP f
                |> onCreate f
                |> nonify

        OnEmail e ->
            model
                |> onCreate
                    (\a ->
                        { a
                            | email = field a.email e
                            , signed = Nothing
                            , otp = RU.emptyField
                        }
                    )
                |> nonify

        OnPassword p ->
            let
                f =
                    \a -> { a | password = field a.password p }
            in
            model
                |> onLogin f
                |> onCreate f
                |> onResetPassword f
                |> nonify

        OnName n ->
            model
                |> onCreate (\a -> { a | name = field a.name n })
                |> nonify

        Focus FUsername foc ->
            let
                f =
                    \a -> { a | username = RU.withFocus a.username foc }
            in
            model
                |> onLogin f
                |> onOTPLogin f
                |> nonify

        Focus FOTP foc ->
            let
                f =
                    \a -> { a | otp = RU.withFocus a.otp foc }
            in
            model
                |> onOTP f
                |> onCreate f
                |> nonify

        Focus FEmail foc ->
            model
                |> onCreate (\a -> { a | email = RU.withFocus a.email foc })
                |> nonify

        Focus FPassword foc ->
            let
                f =
                    \a -> { a | password = RU.withFocus a.password foc }
            in
            model
                |> onLogin f
                |> onCreate f
                |> onResetPassword f
                |> nonify

        Focus FName foc ->
            model
                |> onCreate (\a -> { a | name = RU.withFocus a.name foc })
                |> nonify

        SwitchToOTP ->
            model
                |> onAuth (\_ -> ASOTPLogin { username = RU.emptyField })
                |> nonify

        SwitchToCreate ->
            model
                |> onAuth
                    (\_ ->
                        ASCreate
                            { email = RU.emptyField
                            , name = RU.emptyField
                            , password = RU.emptyField
                            , show = False
                            , signed = Nothing
                            , otp = RU.emptyField
                            }
                    )
                |> nonify

        SwitchToLogin ->
            model
                |> onAuth
                    (\_ ->
                        ASLogin
                            { username = RU.emptyField
                            , password = RU.emptyField
                            }
                    )
                |> nonify

        OnUnloading v ->
            ( { model | unloading = v }, Cmd.none )


view :
    R.In
    -> Model
    -> (Msg -> msg)
    -> Maybe (E.Element msg)
    -> E.Element msg
    -> E.Element msg
view in_ model tagger md inner =
    view0 in_
        model
        tagger
        md
        [ header in_ model |> E.map tagger
        , E.el [ ER.mainContent, E.width E.fill, E.height E.fill ] inner
        , footer in_ model |> E.map tagger
        ]


naked :
    R.In
    -> Model
    -> (Msg -> msg)
    -> Maybe (E.Element msg)
    -> E.Element msg
    -> E.Element msg
naked in_ model tagger md inner =
    view0 in_
        model
        tagger
        md
        [ E.el [ ER.mainContent, E.width E.fill, E.height E.fill ] inner ]


view0 :
    R.In
    -> Model
    -> (Msg -> msg)
    -> Maybe (E.Element msg)
    -> List (E.Element msg)
    -> E.Element msg
view0 in_ model tagger md lst =
    E.column
        [ E.height E.fill
        , E.width E.fill
        , Bg.color S.gray9
        , EF.color S.green0
        , E.htmlAttribute (HA.attribute "id" "base-main")
        , (case md of
            Just d ->
                d

            Nothing ->
                E.map tagger <|
                    if model.unloading then
                        unloading in_ model

                    else if model.switcher.visible then
                        switcherDialog in_ model

                    else if model.recent.visible then
                        recentDialog in_ model

                    else if model.likes.visible then
                        likesDialog in_ model

                    else if model.showHelp then
                        help in_ (model.config.local /= Nothing) model

                    else if model.qn.visible then
                        quick in_ model

                    else
                        case model.authenticating of
                            Just auth ->
                                authPopup in_ auth

                            _ ->
                                E.none
          )
            |> E.inFront
        ]
        lst


quick : R.In -> Model -> E.Element Msg
quick in_ m =
    let
        width =
            400

        left =
            case in_.device.class of
                E.Phone ->
                    String.fromFloat (toFloat in_.width / 2 - 200)

                _ ->
                    String.fromInt (in_.width - width - 100)
    in
    E.column
        [ E.width E.fill
        , E.height E.fill
        , Bg.color (E.rgba255 241 243 245 0.5)
        , E.paddingEach { edges | top = round (0.3 * toFloat in_.height) }
        ]
        [ E.column
            [ E.alignTop
            , E.width (E.px width)
            , Bg.color S.gray7
            , EB.color S.green2
            , EB.width CS.border2
            , EB.rounded CS.borderRadius4
            , RU.style "position" "fixed"
            , RU.style "top" "100px"
            , RU.style "left" (left ++ "px")
            ]
            [ E.row
                [ EB.color S.gray4
                , E.width E.fill
                , E.paddingXY 18 12
                , Bg.color S.green2
                , EF.color S.green6
                , E.spacing 10
                ]
                [ RU.text [ EF.size 13 ] "✏️"
                , E.text "Quick Note"
                , RU.text
                    [ E.pointer
                    , E.alignRight
                    , EE.onClick (ShortCut KHideQN)
                    , RU.title "Close"
                    , EF.size 14
                    ]
                    "🙅"
                ]
            , E.column [ E.padding 20, E.spacing 15, E.width E.fill ]
                [ EI.multiline
                    [ EI.focusedOnLoad
                    , E.height (E.fill |> E.maximum width |> E.minimum 100)
                    , E.width (E.fill |> E.maximum width)
                    , E.scrollbars
                    , EF.family [ EF.monospace ]
                    ]
                    { onChange = QNText
                    , text = m.qn.field.value
                    , placeholder = Nothing
                    , label = EI.labelHidden "Quick Note"
                    , spellcheck = True
                    }
                , fieldError 0 m.qn.field
                , L.submit "Save" [ m.qn.field ] QNSave
                ]
            ]
        ]


switcherDialog : R.In -> Model -> E.Element Msg
switcherDialog in_ m =
    let
        ( width, v ) =
            switcher m
    in
    Dialog.view in_
        ( "🚀 Switch Project", ShortCut KHideSwitcher )
        ( width, m.dialogHeight )
        v


switcher : Model -> ( Int, E.Element Msg )
switcher m =
    let
        track : Bool -> Int -> Content.ContentMeta -> E.Element Msg
        track withShortcut idx t =
            let
                emojified =
                    (RU.yesno t.public Emoji.public Emoji.private ++ " ")
                        |> L.prefixR t.title.rendered
                        |> RU.htmlLine []

                extra =
                    if idx < 9 && withShortcut then
                        RU.text [ EF.size 12, E.alignTop, EF.color S.gray3 ]
                            (String.fromInt (idx + 1))

                    else
                        E.none
            in
            E.link
                [ E.pointer
                , RU.yesno (m.switcher.current == idx && withShortcut)
                    EF.bold
                    EF.regular
                ]
                { url = t.url, label = E.row [ E.spacing 5 ] [ emojified, extra ] }

        addProject : E.Element Msg
        addProject =
            -- projects can't be created locally for now
            RU.iff (m.config.local == Nothing) <|
                E.link
                    [ EE.onClick (ShortCut KHideSwitcher)
                    , Bg.color S.gray5
                    , E.width E.shrink
                    , EB.color S.gray3
                    , EB.width 1
                    , E.padding 5
                    , EB.rounded 2
                    , E.pointer
                    , EF.size 14
                    ]
                    { url = "/p/create-project/"
                    , label = E.text "Create Project"
                    }

        left =
            E.column [ E.padding 20, E.spacing 20, E.width E.fill ]
                [ E.column [ E.spacing 15 ]
                    (List.indexedMap (track True) m.config.tracks)
                , addProject
                ]

        library =
            m.config.inLibrary

        ( width, right ) =
            if List.isEmpty library then
                ( 380, E.none )

            else
                ( 500
                , E.column [ E.width E.fill, E.padding 15, E.alignTop, E.spacing 20 ]
                    (List.indexedMap (track False) library)
                )
    in
    ( width, E.row [ E.width E.fill ] [ left, right ] )


dialogOpen : Model -> Bool
dialogOpen m =
    m.switcher.visible || m.recent.visible || m.likes.visible


likesDialog : R.In -> Model -> E.Element Msg
likesDialog in_ m =
    let
        ( width, v ) =
            likes m
    in
    Dialog.view in_
        ( " Liked", ShortCut KHideLikes )
        ( width, m.dialogHeight )
        v


likes : Model -> ( Int, E.Element Msg )
likes m =
    let
        track : Int -> Content.ContentMeta -> E.Element Msg
        track idx t =
            let
                _ =
                    Debug.log "meta" idx

                title =
                    Debug.log "render-title" t.title.rendered |> RU.htmlLine []
            in
            E.link [ E.pointer, RU.yesno (m.likes.current == idx) EF.bold EF.regular ]
                { url = t.url, label = E.row [ E.spacing 5 ] [ title ] }

        page : E.Element Msg
        page =
            E.link [ E.pointer ]
                { url = "/p/likes/", label = E.text "All Liked Documents" }

        left =
            E.column [ E.padding 20, E.spacing 20, E.width E.fill ]
                [ E.column [ E.spacing 15 ]
                    (List.indexedMap track m.config.likes)
                , page
                ]
    in
    ( 400, E.row [ E.width E.fill ] [ left ] )


recentDialog : R.In -> Model -> E.Element Msg
recentDialog in_ m =
    let
        ( width, v ) =
            recent in_ m
    in
    Dialog.view in_
        ( " Recent Documents", ShortCut KHideRecent )
        ( width, m.dialogHeight )
        v


recent : R.In -> Model -> ( Int, E.Element Msg )
recent in_ m =
    let
        track : Int -> Content.ContentMeta -> E.Element Msg
        track idx t =
            let
                _ =
                    Debug.log "meta" idx

                title =
                    Debug.log "render-title" t.title.rendered |> RU.htmlLine []
            in
            E.link [ E.pointer, RU.yesno (m.recent.current == idx) EF.bold EF.regular ]
                { url = t.url, label = E.row [ E.spacing 5 ] [ title ] }

        left =
            E.column [ E.padding 20, E.spacing 20, E.width E.fill ]
                [ E.column [ E.spacing 15 ]
                    (List.indexedMap track m.config.recent)
                ]
    in
    ( 400, E.row [ E.width E.fill ] [ left ] )


help : R.In -> Bool -> Model -> E.Element Msg
help in_ isLocal m =
    let
        h =
            \k v ->
                E.row [ E.spacing 10, E.width E.fill ]
                    [ RU.text [ EF.bold ] k, RU.text [ E.alignRight ] v ]
    in
    Dialog.view in_ ( "⌘ Keyboard Shortcuts", ShortCut KHideHelp ) ( 384, m.dialogHeight ) <|
        E.column [ E.padding 20, E.spacing 15, E.width E.fill, EF.size 16 ]
            [ h "f" "Toggle 🚀 Switcher"
            , h "r" "Recent ..."
            , h "l" "Liked ..."
            , h "n" "Open ✏️ Quick Capture Window"
            , h "j/k" "Go Up/Down in Switcher"
            , h "Up/Down Arrow" "Go Up/Down in Switcher"
            , h "Enter" "Select current item in Switcher"
            , h "Esc" "Close 🤦 Switcher/Help"
            , RU.iff isLocal (h "S" "Sync Now")
            , h "?" "Toggle ⌘ Help"
            ]


unloading : R.In -> Model -> E.Element Msg
unloading in_ m =
    Dialog.naked in_
        ( 102, m.dialogHeight )
        (RU.text [ E.centerX ] "loading..")


authPopup : R.In -> Authenticating -> E.Element Msg
authPopup in_ auth =
    let
        cta : AuthState -> String
        cta s =
            case s of
                ASCreate _ ->
                    "Create Account"

                ASEnterOTP _ ->
                    "Sign In"

                ASOTPLogin _ ->
                    "Sign In"

                ASLogin _ ->
                    "Sign In"

                ASResetPassword _ ->
                    "Sign In"

        isLogin : AuthState -> Bool
        isLogin s =
            case s of
                ASCreate _ ->
                    False

                ASEnterOTP _ ->
                    True

                ASOTPLogin _ ->
                    True

                ASLogin _ ->
                    True

                ASResetPassword _ ->
                    True

        dialogHeader : E.Element Msg
        dialogHeader =
            E.row
                [ EB.color S.gray4
                , E.width E.fill
                , E.paddingXY 18 12
                , Bg.color S.green2
                , EF.color S.green6
                ]
            <|
                [ E.text (cta auth.state)
                , case auth.state of
                    ASResetPassword _ ->
                        E.none

                    _ ->
                        RU.text
                            [ E.pointer
                            , E.alignRight
                            , EF.size 16
                            , EE.onClick ClosePopup
                            , RU.title "Close"
                            ]
                            "🙅"
                ]

        authMessage : E.Element Msg
        authMessage =
            E.paragraph
                [ E.paddingEach { edges | left = 14, right = 14, bottom = 8 }
                , E.width E.fill
                , E.spacing 10
                , EF.size 16
                ]
                [ E.text <|
                    case auth.state of
                        ASOTPLogin _ ->
                            """
                                Everybody forgets! Enter your email or username and we
                                will send you an "one time password" over email.
                            """

                        ASResetPassword _ ->
                            """
                                Please reset your password.
                            """

                        _ ->
                            if String.isEmpty auth.title then
                                ""

                            else
                                "In order to "
                                    ++ auth.title
                                    ++ RU.yesno (isLogin auth.state)
                                        ", please sign in."
                                        ", please create your account first."
                ]

        aField :
            (List (E.Attribute Msg)
             ->
                { onChange : String -> Msg
                , text : String
                , placeholder : Maybe (EI.Placeholder Msg)
                , label : EI.Label Msg
                }
             -> E.Element Msg
            )
            -> (String -> Msg)
            -> String
            -> RU.Field
            -> Focus
            -> E.Element Msg
        aField field onChange name fieldV foc =
            E.column [ E.width E.fill, E.spacing 10 ]
                [ E.el [ E.paddingXY 14 0, E.width E.fill, RU.onEnter Submit ] <|
                    field
                        [ E.width E.fill
                        , EE.onFocus (Focus foc True)
                        , EE.onLoseFocus (Focus foc False)
                        ]
                        { onChange = onChange
                        , text = fieldV.value
                        , placeholder =
                            Just (EI.placeholder [] (E.text <| String.toLower name))
                        , label = EI.labelAbove [ E.paddingXY 4 0 ] (E.text name)
                        }
                , fieldError 16 fieldV
                ]

        password : RU.Field -> Bool -> E.Element Msg -> E.Element Msg
        password p show extra =
            E.column [ E.width E.fill, E.spacing 10 ]
                [ E.el [ E.paddingXY 14 0, E.width E.fill, RU.onEnter Submit ] <|
                    EI.currentPassword
                        [ E.width E.fill
                        , EE.onFocus (Focus FPassword True)
                        , EE.onLoseFocus (Focus FPassword False)
                        ]
                        { onChange = OnPassword
                        , show = show
                        , text = p.value
                        , placeholder =
                            Just (EI.placeholder [] (E.text "password"))
                        , label =
                            EI.labelAbove [ E.paddingXY 4 0 ]
                                (E.row [ E.width E.fill ]
                                    [ E.text "Password"
                                    , E.el
                                        [ E.alignRight
                                        , E.pointer
                                        , EF.size 14
                                        , EB.widthEach { edges | bottom = 1 }
                                        , EB.color S.gray4
                                        ]
                                        extra
                                    ]
                                )
                        }
                , fieldError 16 p
                ]

        submitButton : E.Element Msg
        submitButton =
            let
                ( fields, txt, extra ) =
                    case auth.state of
                        ASLogin d ->
                            ( [ d.username, d.password ], "Sign In", E.none )

                        ASOTPLogin d ->
                            ( [ d.username ]
                            , "Send OTP Email"
                            , E.el
                                [ E.pointer
                                , E.alignRight
                                , EF.size 14
                                , EB.widthEach { edges | bottom = 1 }
                                , EB.color S.gray4
                                , EE.onClick SwitchToLogin
                                ]
                                (E.text "Use Password?")
                            )

                        ASEnterOTP d ->
                            ( [ d.otp ], "Verify OTP", E.none )

                        ASResetPassword d ->
                            ( [ d.password ], "Reset Password", E.none )

                        ASCreate d ->
                            ( [ d.name, d.email, d.password ]
                                ++ RU.yesno (d.signed == Nothing) [] [ d.otp ]
                            , RU.yesno (d.signed == Nothing)
                                "Create Account"
                                "Verify OTP"
                            , E.none
                            )
            in
            E.row
                [ E.paddingEach { left = 16, bottom = 6, top = 5, right = 16 }
                , E.width E.fill
                ]
                [ L.submit txt fields Submit, extra ]

        showHidePassword : Bool -> E.Element Msg
        showHidePassword show =
            E.el
                [ E.htmlAttribute
                    (HE.preventDefaultOn "click"
                        (JD.succeed ( ToggleShowPassword, True ))
                    )
                ]
                (E.text (RU.yesno show "Hide Password" "Show Password"))

        authForm : AuthState -> List (E.Element Msg)
        authForm s =
            case s of
                ASLogin d ->
                    [ aField EI.email
                        OnUsername
                        "Username or Email"
                        d.username
                        FUsername
                    , password d.password False <|
                        E.el
                            [ E.htmlAttribute
                                (HE.preventDefaultOn "click"
                                    (JD.succeed ( SwitchToOTP, True ))
                                )
                            ]
                            (E.text "Forgot Password?")
                    ]

                ASOTPLogin d ->
                    [ aField EI.email
                        OnUsername
                        "Username or Email"
                        d.username
                        FUsername
                    ]

                ASCreate d ->
                    [ aField EI.email OnEmail "Email" d.email FEmail
                    , aField EI.text OnName "Name" d.name FName
                    , password d.password d.show (showHidePassword d.show)
                    ]
                        ++ (case d.signed of
                                Just _ ->
                                    [ aField EI.text OnOTP "OTP" d.otp FOTP ]

                                Nothing ->
                                    []
                           )

                ASEnterOTP d ->
                    [ aField EI.text OnOTP "OTP" d.otp FOTP ]

                ASResetPassword d ->
                    [ password d.password d.show (showHidePassword d.show) ]

        dialogFooter : E.Element Msg
        dialogFooter =
            case auth.state of
                ASResetPassword _ ->
                    E.none

                _ ->
                    E.row
                        [ EB.widthEach { edges | top = 1 }
                        , EB.color S.gray4
                        , E.paddingEach { edges | top = 15, left = 16, right = 16 }
                        , E.width E.fill
                        , E.spacing 7
                        , EF.size 16
                        ]
                        [ E.text
                            (RU.yesno (isLogin auth.state)
                                "Don't have an account?"
                                "Already have account?"
                            )
                        , E.el
                            [ EB.widthEach { edges | bottom = 1 }
                            , EB.color S.gray4
                            , E.pointer
                            , EE.onClick
                                (RU.yesno (isLogin auth.state)
                                    SwitchToCreate
                                    SwitchToLogin
                                )
                            ]
                            (E.text
                                (RU.yesno (isLogin auth.state)
                                    "Create account"
                                    "Log in"
                                )
                            )
                        ]
    in
    E.column
        [ E.width E.fill
        , E.height E.fill
        , Bg.color (E.rgba255 241 243 245 0.5)
        , E.paddingEach { edges | top = round (0.2 * toFloat in_.height) }
        ]
        [ E.column
            [ E.alignTop
            , E.centerX
            , E.width
                (RU.yesno (in_.device.class == E.Phone)
                    (E.px (in_.width - 40))
                    CS.s384
                )
            , E.spacing 12
            , Bg.color S.gray7
            , EB.color S.green2
            , EB.width CS.border4
            , EB.rounded CS.borderRadius4
            , E.paddingEach { edges | bottom = 16 }
            ]
            [ dialogHeader
            , authMessage
            , authForm auth.state |> E.column [ E.width E.fill, E.spacing 10 ]
            , submitButton
            , dialogFooter
            ]
        ]


fieldError : Int -> RU.Field -> E.Element Msg
fieldError p f =
    case f.error of
        Just e ->
            E.el [ E.paddingXY p 0, EF.color S.red4, EF.size 14 ] (E.text e)

        Nothing ->
            E.none


header : R.In -> Model -> E.Element Msg
header in_ m =
    let
        showName : String -> E.Element Msg
        showName name =
            let
                style =
                    [ EF.alignRight
                    , E.paddingXY 10 5
                    , EB.widthEach { edges | bottom = 1 }
                    , E.mouseOver [ Bg.color S.gray6 ]
                    , E.width E.fill
                    ]

                menu =
                    RU.yesno (m.onNameHovering && m.config.local == Nothing)
                        (E.column
                            ([ E.alignRight
                             , EB.widthEach { edges | top = 1, left = 1, right = 1 }
                             , E.moveDown 2
                             , Bg.color S.gray7
                             ]
                                ++ List.map E.htmlAttribute (Animation.render m.onName)
                            )
                            [ E.link style
                                { url = Routes.settings, label = E.text "settings" }
                            , E.link style
                                { url = Routes.logout, label = E.text "👋 logout" }
                            ]
                        )
                        E.none
            in
            E.el
                [ E.alignRight
                , EE.onMouseEnter (Hover True)
                , EE.onMouseLeave (Hover False)
                , E.below menu
                ]
                (E.text name)
    in
    E.row
        [ RU.id "base-header"
        , E.width E.fill
        , ER.navigation
        , CS.spacing10
        , Bg.color S.gray6
        , E.paddingEach
            { top = 12
            , left =
                case in_.notch of
                    R.NotchOnLeft ->
                        42

                    _ ->
                        12
            , right =
                case in_.notch of
                    R.NotchOnRight ->
                        42

                    _ ->
                        12
            , bottom = 12
            }
        , EB.widthEach { edges | top = CS.border4 }
        , EB.color S.green2
        ]
        (E.link [ E.alignLeft, E.pointer ]
            { url = Routes.index
            , label =
                RU.yesno (m.config.local == Nothing)
                    (E.text "fifthtry")
                    (E.row []
                        [ E.text "5"
                        , RU.text
                            [ RU.style "position" "relative"
                            , RU.style "top" "-0.35em"
                            , RU.style "font-size" "60%"
                            , EF.bold
                            ]
                            "th"
                        , RU.text [ E.paddingEach { edges | left = 2 } ] "try"
                        ]
                    )
            }
            :: RU.iff (List.length m.config.tracks /= 0)
                (RU.text [ E.alignLeft, E.pointer, EE.onClick (ShortCut KShowSwitcher) ]
                    "🚀"
                )
            :: RU.mif m.config.local
                (\l ->
                    E.link
                        ([ E.centerX, E.pointer, EF.size 10 ]
                            ++ (if l.hasLocalChanges then
                                    [ EF.bold
                                    , E.htmlAttribute
                                        (HA.title "Has un-synced local changes.")
                                    ]

                                else
                                    []
                               )
                        )
                        { url = "/sync/"
                        , label =
                            E.text
                                (case l.lastSyncOn of
                                    Just t ->
                                        "Synced "
                                            ++ TD.inWords in_.now
                                                (Time.millisToPosix t)
                                            ++ " ago"
                                            ++ (if l.conflicts /= 0 then
                                                    ", with "
                                                        ++ String.fromInt
                                                            l.conflicts
                                                        ++ " conflicts."

                                                else
                                                    "."
                                               )

                                    _ ->
                                        "Sync Now"
                                )
                        }
                )
            :: E.row [ E.alignRight, E.spacing 8 ]
                [ RU.iff
                    ((m.config.name /= Nothing) && not (List.isEmpty m.config.tracks))
                    (RU.text
                        [ EF.size 12
                        , E.pointer
                        , EE.onClick (ShortCut KQuickNote)
                        ]
                        Emoji.pencil
                    )
                , RU.iff
                    ((in_.device.class == E.Desktop) && (m.config.name /= Nothing))
                    (RU.text
                        [ E.pointer, EE.onClick (ShortCut KShowHelp) ]
                        "⌘"
                    )
                ]
            :: (case m.config.name of
                    Just name ->
                        [ showName name ]

                    Nothing ->
                        RU.yesno (m.config.local == Nothing)
                            [ E.el
                                [ E.pointer
                                , E.alignRight
                                , EE.onClick SignIn
                                ]
                                (E.text "Sign In")

                            -- , I.addCircle CT.S16 S.red4 S.gray0
                            , E.el
                                [ Bg.color S.green2
                                , CS.padding8
                                , EF.color S.green6
                                , EB.rounded CS.borderRadius4
                                , E.pointer
                                ]
                              <|
                                E.el
                                    [ E.alignRight
                                    , E.pointer
                                    , EE.onClick SignUp
                                    ]
                                    (E.text "Create Account")
                            ]
                            []
               )
        )


footer : R.In -> Model -> E.Element Msg
footer in_ m =
    E.row
        [ RU.id "base-footer"
        , E.alignBottom
        , ER.footer
        , E.width E.fill
        , E.height E.shrink
        , EB.color S.gray7
        , CS.padding12
        ]
        [ E.el [ E.alignLeft ] (E.text "©️2020, Fifthtry")
        , RU.iff (m.config.local == Nothing && in_.device.class /= E.Phone) <|
            E.download
                [ E.centerX ]
                { url = "http://downloads.fifthtry.com/5thtry.dmg"
                , label = E.text "Download 5thtry Local (OS X)"
                }
        , E.row [ E.alignRight, E.spacing 5 ]
            [ E.text "Powered by"
            , E.link
                [ EB.widthEach { edges | bottom = 1 }
                , RU.title m.config.build
                ]
                { url = "/amitu/realm/", label = E.text "Realm" }
            ]
        ]


isLoggedIn : Model -> Bool
isLoggedIn m =
    case m.config.name of
        Just _ ->
            True

        Nothing ->
            False


authenticate : String -> String -> Model -> Model
authenticate title token m =
    { m
        | authenticating =
            Just
                { title = title
                , token = token
                , state =
                    ASLogin
                        { username = RU.emptyField, password = RU.emptyField }
                }
    }


subscriptions : R.In -> (Msg -> msg) -> Model -> Sub msg
subscriptions in_ tagger m =
    let
        d =
            60 * 1000

        every =
            case m.config.local of
                Just l ->
                    case l.lastSyncOn of
                        Just las ->
                            if Time.posixToMillis in_.now - las < 60 * 1000 then
                                1000

                            else
                                d

                        Nothing ->
                            d

                _ ->
                    d

        select : Int -> Bool -> Msg
        select i always =
            RU.yesno (always || m.switcher.visible)
                (ShortCut (KSwitcherSelect i))
                NoOp

        shortcuts : JD.Decoder Msg
        shortcuts =
            JD.map3
                (\id key special ->
                    case ( String.toUpper id, key, special ) of
                        ( "BODY", "f", False ) ->
                            RU.yesno m.switcher.visible
                                KHideSwitcher
                                KShowSwitcher
                                |> ShortCut

                        ( "BODY", "r", False ) ->
                            RU.yesno m.recent.visible KHideRecent KShowRecent
                                |> ShortCut

                        ( "BODY", "l", False ) ->
                            RU.yesno m.likes.visible KHideLikes KShowLikes
                                |> ShortCut

                        ( "BODY", "?", _ ) ->
                            RU.yesno m.showHelp KHideHelp KShowHelp
                                |> ShortCut

                        ( "BODY", "Enter", _ ) ->
                            if m.switcher.visible then
                                ShortCut (KSwitcherSelect m.switcher.current)

                            else if m.recent.visible then
                                ShortCut (KRecentSelect m.recent.current)

                            else if m.likes.visible then
                                ShortCut (KLikesSelect m.likes.current)

                            else
                                NoOp

                        ( "BODY", "!", _ ) ->
                            select 0 True

                        ( "BODY", "1", _ ) ->
                            select 0 False

                        ( "BODY", "@", _ ) ->
                            select 1 True

                        ( "BODY", "2", _ ) ->
                            select 1 False

                        ( "BODY", "#", _ ) ->
                            select 2 True

                        ( "BODY", "3", _ ) ->
                            select 2 False

                        ( "BODY", "$", _ ) ->
                            select 3 True

                        ( "BODY", "4", _ ) ->
                            select 3 False

                        ( "BODY", "%", _ ) ->
                            select 4 True

                        ( "BODY", "5", _ ) ->
                            select 4 False

                        ( "BODY", "^", _ ) ->
                            select 5 True

                        ( "BODY", "6", _ ) ->
                            select 5 False

                        ( "BODY", "&", _ ) ->
                            select 6 True

                        ( "BODY", "7", _ ) ->
                            select 6 False

                        ( "BODY", "*", _ ) ->
                            select 7 True

                        ( "BODY", "8", _ ) ->
                            select 7 False

                        ( "BODY", "(", _ ) ->
                            select 8 False

                        ( "BODY", "9", _ ) ->
                            select 8 False

                        ( "BODY", "j", _ ) ->
                            if m.switcher.visible then
                                KSwitcherNext |> ShortCut

                            else if m.recent.visible then
                                KRecentNext |> ShortCut

                            else if m.likes.visible then
                                KLikesNext |> ShortCut

                            else
                                NoOp

                        ( "BODY", "ArrowDown", _ ) ->
                            if m.switcher.visible then
                                KSwitcherNext |> ShortCut

                            else if m.recent.visible then
                                KRecentNext |> ShortCut

                            else if m.likes.visible then
                                KLikesNext |> ShortCut

                            else
                                NoOp

                        ( "BODY", "k", _ ) ->
                            if m.switcher.visible then
                                KSwitcherPrev |> ShortCut

                            else if m.recent.visible then
                                KRecentPrev |> ShortCut

                            else if m.likes.visible then
                                KLikesPrev |> ShortCut

                            else
                                NoOp

                        ( "BODY", "ArrowUp", _ ) ->
                            if m.switcher.visible then
                                KSwitcherPrev |> ShortCut

                            else if m.recent.visible then
                                KRecentPrev |> ShortCut

                            else if m.likes.visible then
                                KLikesPrev |> ShortCut

                            else
                                NoOp

                        ( "BODY", "Escape", _ ) ->
                            (if m.showHelp then
                                KHideHelp

                             else if m.switcher.visible then
                                KHideSwitcher

                             else if m.recent.visible then
                                KHideRecent

                             else if m.likes.visible then
                                KHideLikes

                             else
                                KHideQN
                            )
                                |> ShortCut

                        ( "BODY", "S", _ ) ->
                            RU.yesno (m.config.local /= Nothing)
                                (ShortCut KGoToSync)
                                NoOp

                        ( "BODY", "n", _ ) ->
                            ShortCut KQuickNote

                        _ ->
                            NoOp
                )
                (JD.at [ "target", "nodeName" ] JD.string)
                (JD.field "key" JD.string)
                (JD.field "metaKey" JD.bool
                    |> JD.andThen
                        (\v ->
                            if v then
                                JD.succeed True

                            else
                                JD.field "ctrlKey" JD.bool
                        )
                )
    in
    [ Animation.subscription Animate [ m.onName ]
    , RP.onUnloading OnUnloading

    -- on sync page we show time modified since, this is for that
    , RU.subIfNothing m.config.local (Time.every every (always NoOp))
    , RU.subIfJust m.config.name (BE.onKeyDown shortcuts)

    -- we do this so dialog can get re-centered
    , BE.onResize (always (always NoOp))
    ]
        |> List.map (Sub.map tagger)
        |> Sub.batch


config : JD.Decoder Config
config =
    JD.map8 Config
        (JD.field "name" (RU.maybe JD.string))
        (JD.field "local" (JD.maybe local))
        (JD.field "build" JD.string)
        (JD.field "tracks" (JD.list Content.contentMeta))
        (RU.fieldWithDefault "in_library" [] (JD.list Content.contentMeta))
        (RU.fmaybe "current_track" JD.string)
        (RU.fieldWithDefault "recent" [] (JD.list Content.contentMeta))
        (RU.fieldWithDefault "likes" [] (JD.list Content.contentMeta))


configE : Config -> JE.Value
configE b =
    JE.object
        [ ( "name", RU.maybeS b.name )
        , ( "local", RU.maybeE localE b.local )
        , ( "build", JE.string b.build )
        , ( "tracks", JE.list Content.contentMetaE b.tracks )
        , ( "in_library", JE.list Content.contentMetaE b.inLibrary )
        , ( "current_track", RU.maybeE JE.string b.currentTrack )
        , ( "recent", JE.list Content.contentMetaE b.recent )
        , ( "likes", JE.list Content.contentMetaE b.recent )
        ]


local : JD.Decoder Local
local =
    JD.succeed Local
        |> R.field "conflicts" JD.int
        |> R.field "last_sync_on" (JD.maybe JD.int)
        |> R.field "now" JD.int
        |> R.field "has_local_changes" JD.bool


localE : Local -> JE.Value
localE l =
    JE.object
        [ ( "conflicts", JE.int l.conflicts )
        , ( "last_sync_on", RU.maybeE JE.int l.lastSyncOn )
        , ( "now", JE.int l.now )
        , ( "has_local_changes", JE.bool l.hasLocalChanges )
        ]
