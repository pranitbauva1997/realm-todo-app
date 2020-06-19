module System exposing (..)

import Element as E
import Element.Font as EF


type IconSize
    = S12
    | S16
    | S24
    | S32


size : IconSize -> Int
size s =
    case s of
        S12 ->
            12

        S16 ->
            16

        S24 ->
            24

        S32 ->
            32



-- Font size


f12 : E.Attr decorative msg
f12 =
    EF.size 12


f14 : E.Attr decorative msg
f14 =
    EF.size 14


f16 : E.Attr decorative msg
f16 =
    EF.size 16


f18 : E.Attr decorative msg
f18 =
    EF.size 18


f20 : E.Attr decorative msg
f20 =
    EF.size 20


f24 : E.Attr decorative msg
f24 =
    EF.size 24


f32 : E.Attr decorative msg
f32 =
    EF.size 32


f44 : E.Attr decorative msg
f44 =
    EF.size 44



-- Font weight
-- Line height
--------------------------------------------------------------
-- Color --
--------------------------------------------------------------
-- greys: Text, backgrounds, panels, form controls


gray0 : E.Color
gray0 =
    E.rgb255 34 37 42


gray1 : E.Color
gray1 =
    E.rgb255 53 58 63


gray2 : E.Color
gray2 =
    E.rgb255 74 80 86


gray3 : E.Color
gray3 =
    E.rgb255 135 142 149


gray4 : E.Color
gray4 =
    E.rgb255 174 181 188


gray5 : E.Color
gray5 =
    E.rgb255 207 212 217


gray6 : E.Color
gray6 =
    E.rgb255 223 226 230


codeBG : E.Color
codeBG =
    E.rgb255 43 48 59


gray7 : E.Color
gray7 =
    E.rgb255 234 236 239


gray8 : E.Color
gray8 =
    E.rgb255 241 243 245


gray9 : E.Color
gray9 =
    E.rgb255 248 249 250



-- white


white : E.Color
white =
    E.rgb255 255 255 255



-- reds: confirming a destructive action, errors, dangers etc


red0 : E.Color
red0 =
    E.rgb255 89 30 27


red1 : E.Color
red1 =
    E.rgb255 126 37 33


red2 : E.Color
red2 =
    E.rgb255 169 48 41


red3 : E.Color
red3 =
    E.rgb255 203 64 57


red4 : E.Color
red4 =
    E.rgb255 213 107 104


red5 : E.Color
red5 =
    E.rgb255 234 173 172


red6 : E.Color
red6 =
    E.rgb255 247 231 231



-- yellows: warning messages


yellow0 : E.Color
yellow0 =
    E.rgb255 89 72 29


yellow1 : E.Color
yellow1 =
    E.rgb255 136 109 47


yellow2 : E.Color
yellow2 =
    E.rgb255 197 165 80


yellow3 : E.Color
yellow3 =
    E.rgb255 238 202 116


yellow4 : E.Color
yellow4 =
    E.rgb255 246 226 167


yellow5 : E.Color
yellow5 =
    E.rgb255 251 243 218


yellow6 : E.Color
yellow6 =
    E.rgb255 255 252 245



-- greens: success, positive trends


green0 : E.Color
green0 =
    E.rgb255 40 80 59


green1 : E.Color
green1 =
    E.rgb255 57 117 70


green2 : E.Color
green2 =
    E.rgb255 77 154 95


green3 : E.Color
green3 =
    E.rgb255 100 189 121


green4 : E.Color
green4 =
    E.rgb255 141 214 164


green5 : E.Color
green5 =
    E.rgb255 183 235 196


green6 : E.Color
green6 =
    E.rgb255 232 251 237



-- primary: the colors that determine the overall look of a site — the ones that make
-- you think of Facebook as “blue”.


primary0 : E.Color
primary0 =
    E.rgb255 23 40 56


primary1 : E.Color
primary1 =
    E.rgb255 38 73 110


primary2 : E.Color
primary2 =
    E.rgb255 53 104 157


primary3 : E.Color
primary3 =
    E.rgb255 70 131 195


primary4 : E.Color
primary4 =
    E.rgb255 112 162 211


primary5 : E.Color
primary5 =
    E.rgb255 178 211 242


primary6 : E.Color
primary6 =
    E.rgb255 241 248 254



-- Spacing


spacing10 : E.Attribute msg
spacing10 =
    E.spacing 10



-- Padding


padding4 : E.Attribute msg
padding4 =
    E.padding 4


padding8 : E.Attribute msg
padding8 =
    E.padding 8


padding12 : E.Attribute msg
padding12 =
    E.padding 12



-- Width


s4 : E.Length
s4 =
    E.px 4


s8 : E.Length
s8 =
    E.px 8


s12 : E.Length
s12 =
    E.px 12


s16 : E.Length
s16 =
    E.px 16


s24 : E.Length
s24 =
    E.px 24


s32 : E.Length
s32 =
    E.px 32


s48 : E.Length
s48 =
    E.px 48


s64 : E.Length
s64 =
    E.px 64


s96 : E.Length
s96 =
    E.px 96


s129 : E.Length
s129 =
    E.px 129


s192 : E.Length
s192 =
    E.px 192


s256 : E.Length
s256 =
    E.px 256


s384 : E.Length
s384 =
    E.px 384


s512 : E.Length
s512 =
    E.px 512


s640 : E.Length
s640 =
    E.px 640


s768 : E.Length
s768 =
    E.px 768



-- borders


border2 : Int
border2 =
    2


border4 : Int
border4 =
    4


borderRadius2 : Int
borderRadius2 =
    2


borderRadius4 : Int
borderRadius4 =
    4



-- Box shadows
-- utils


edges : { top : Int, right : Int, bottom : Int, left : Int }
edges =
    { top = 0, right = 0, bottom = 0, left = 0 }
