module Tests.NoUnused.Patterns exposing (all)

import NoUnused.Patterns exposing (rule)
import Review.Test
import Test exposing (Test, describe, test)


details : List String
details =
    [ "You should either use this value somewhere, or remove it at the location I pointed at."
    ]


all : Test
all =
    describe "NoUnused.Patterns"
        [ describe "in Case branches" caseTests
        , describe "in Function arguments" functionArgumentTests
        , describe "in Lambda arguments" lambdaArgumentTests
        , describe "in Let destructuring" letDestructuringTests
        , describe "in Let Functions" letFunctionTests
        , describe "with list pattern" listPatternTests
        , describe "with record pattern" recordPatternTests
        , describe "with tuple pattern" tuplePatternTests
        , describe "with uncons pattern" unconsPatternTests
        ]


caseTests : List Test
caseTests =
    [ test "reports unused values" <|
        \() ->
            """
module A exposing (..)
foo =
    case bar of
        bish ->
            Nothing
        bash ->
            Nothing
"""
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error
                        { message = "Pattern `bish` is not used"
                        , details = details
                        , under = "bish"
                        }
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
foo =
    case bar of
        _ ->
            Nothing
        bash ->
            Nothing
"""
                    , Review.Test.error
                        { message = "Pattern `bash` is not used"
                        , details = details
                        , under = "bash"
                        }
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
foo =
    case bar of
        bish ->
            Nothing
        _ ->
            Nothing
"""
                    ]
    ]


functionArgumentTests : List Test
functionArgumentTests =
    [ test "should report unused arguments" <|
        \() ->
            """
module A exposing (..)
foo : Int -> String -> String -> String
foo one two three =
    three
"""
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error
                        { message = "Pattern `one` is not used"
                        , details = details
                        , under = "one"
                        }
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
foo : Int -> String -> String -> String
foo _ two three =
    three
"""
                    , Review.Test.error
                        { message = "Pattern `two` is not used"
                        , details = details
                        , under = "two"
                        }
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
foo : Int -> String -> String -> String
foo one _ three =
    three
"""
                    ]
    , test "should not consider values from other modules" <|
        \() ->
            """
module A exposing (..)
foo one =
    Bar.one
"""
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error
                        { message = "Pattern `one` is not used"
                        , details = details
                        , under = "one"
                        }
                        |> Review.Test.atExactly { start = { row = 3, column = 5 }, end = { row = 3, column = 8 } }
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
foo _ =
    Bar.one
"""
                    ]
    ]


lambdaArgumentTests : List Test
lambdaArgumentTests =
    [ test "should report unused arguments" <|
        \() ->
            """
module A exposing (..)
foo =
    List.map (\\value -> Nothing) list
"""
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error
                        { message = "Pattern `value` is not used"
                        , details = details
                        , under = "value"
                        }
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
foo =
    List.map (\\_ -> Nothing) list
"""
                    ]
    ]


letDestructuringTests : List Test
letDestructuringTests =
    [ test "should report unused values" <|
        \() ->
            """
module A exposing (..)
foo =
    let
        ( left, right ) =
            tupleValue
    in
    left
"""
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error
                        { message = "Pattern `right` is not used"
                        , details = details
                        , under = "right"
                        }
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
foo =
    let
        ( left, _ ) =
            tupleValue
    in
    left
"""
                    ]
    ]


letFunctionTests : List Test
letFunctionTests =
    [ test "should report unused arguments" <|
        \() ->
            """
module A exposing (..)
foo =
    let
        one oneValue =
            1
        two twoValue =
            2
    in
    one two 3
"""
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error
                        { message = "Pattern `oneValue` is not used"
                        , details = details
                        , under = "oneValue"
                        }
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
foo =
    let
        one _ =
            1
        two twoValue =
            2
    in
    one two 3
"""
                    , Review.Test.error
                        { message = "Pattern `twoValue` is not used"
                        , details = details
                        , under = "twoValue"
                        }
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
foo =
    let
        one oneValue =
            1
        two _ =
            2
    in
    one two 3
"""
                    ]
    , test "should report unused let functions" <|
        \() ->
            """
module A exposing (..)
foo =
    let
        value =
            something 5
    in
    bar
"""
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error
                        { message = "Pattern `value` is not used"
                        , details = details
                        , under = "value"
                        }
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
foo =
    let
        _ =
            something 5
    in
    bar
"""
                    ]
    ]



--- PATTERN TESTS ------------------------


listPatternTests : List Test
listPatternTests =
    [ test "should report unused list values" <|
        \() ->
            """
module A exposing (..)
foo =
    case bar of
        [ first, second ] ->
            another
"""
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error
                        { message = "Pattern `first` is not used"
                        , details = details
                        , under = "first"
                        }
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
foo =
    case bar of
        [ _, second ] ->
            another
"""
                    , Review.Test.error
                        { message = "Pattern `second` is not used"
                        , details = details
                        , under = "second"
                        }
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
foo =
    case bar of
        [ first, _ ] ->
            another
"""
                    ]
    ]


recordPatternTests : List Test
recordPatternTests =
    [ test "should replace unused record with `_`" <|
        \() ->
            """
module A exposing (..)
foo =
    let
        { bish, bash } =
            bar
    in
    bosh
"""
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error
                        { message = "Values `bish` and `bash` are not used"
                        , details = [ "You should either use these values somewhere, or remove them at the location I pointed at." ]
                        , under = "{ bish, bash }"
                        }
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
foo =
    let
        _ =
            bar
    in
    bosh
"""
                    ]
    , test "should report unused record values" <|
        \() ->
            """
module A exposing (..)
foo =
    let
        { bish, bash, bosh } =
            bar
    in
    bash
"""
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error
                        { message = "Values `bish` and `bosh` are not used"
                        , details = [ "You should either use these values somewhere, or remove them at the location I pointed at." ]
                        , under = "bish, bash, bosh"
                        }
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
foo =
    let
        {bash} =
            bar
    in
    bash
"""
                    ]
    , test "should report highlight the least amount of values possible" <|
        \() ->
            """
module A exposing (..)
foo =
    let
        { bish, bash, bosh } =
            bar
    in
    bish
"""
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error
                        { message = "Values `bash` and `bosh` are not used"
                        , details = [ "You should either use these values somewhere, or remove them at the location I pointed at." ]
                        , under = "bash, bosh"
                        }
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
foo =
    let
        {bish} =
            bar
    in
    bish
"""
                    ]
    ]


tuplePatternTests : List Test
tuplePatternTests =
    [ test "should report unused tuple values" <|
        \() ->
            """
module A exposing (..)
foo =
    let
        ( bish, bash, bosh ) =
            bar
    in
    bash
"""
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error
                        { message = "Pattern `bish` is not used"
                        , details = details
                        , under = "bish"
                        }
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
foo =
    let
        ( _, bash, bosh ) =
            bar
    in
    bash
"""
                    , Review.Test.error
                        { message = "Pattern `bosh` is not used"
                        , details = details
                        , under = "bosh"
                        }
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
foo =
    let
        ( bish, bash, _ ) =
            bar
    in
    bash
"""
                    ]
    , test "should replace unused tuple with `_`" <|
        \() ->
            """
module A exposing (..)
foo =
    let
        ( bish, bash, _ ) =
            bar
    in
    1
"""
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error
                        { message = "Tuple pattern is not used"
                        , details = [ "You should either use these values somewhere, or remove them at the location I pointed at." ]
                        , under = "( bish, bash, _ )"
                        }
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
foo =
    let
        _ =
            bar
    in
    1
"""
                    ]
    , test "should not report a tuple containing an empty list" <|
        \() ->
            """
module A exposing (..)
foo =
    case bar of
        ( [], _ ) ->
            1
"""
                |> Review.Test.run rule
                |> Review.Test.expectNoErrors
    ]


unconsPatternTests : List Test
unconsPatternTests =
    [ test "should report unused uncons values" <|
        \() ->
            """
module A exposing (..)
foo =
    case list of
        first :: rest ->
            list
"""
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error
                        { message = "Pattern `first` is not used"
                        , details = details
                        , under = "first"
                        }
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
foo =
    case list of
        _ :: rest ->
            list
"""
                    , Review.Test.error
                        { message = "Pattern `rest` is not used"
                        , details = details
                        , under = "rest"
                        }
                        |> Review.Test.whenFixed
                            """
module A exposing (..)
foo =
    case list of
        first :: _ ->
            list
"""
                    ]
    ]



{- TODO

   Patterns:
     - [-] AllPattern
     - [-] UnitPattern
     - [-] CharPattern Char
     - [-] StringPattern String
     - [-] IntPattern Int
     - [-] HexPattern Int
     - [-] FloatPattern Float
     - [x] TuplePattern (List (Node Pattern))
     - [x] RecordPattern (List (Node String))
     - [x] UnConsPattern (Node Pattern) (Node Pattern)
     - [x] ListPattern (List (Node Pattern))
     - [x] VarPattern String
     - [ ] NamedPattern QualifiedNameRef (List (Node Pattern))
     - [ ] AsPattern (Node Pattern) (Node String)
     - [ ] ParenthesizedPattern (Node Pattern)

   Sources:
     - [x] Declaration.FunctionDeclaration { declaration.arguments }
     - [x] Expression.LambdaExpression { args }
     - [x] Expression.LetFunction { declaration.arguments }
     - [x] Expression.LetDestructuring pattern _
     - [x] Expression.Case ( pattern, _ )

    Extras:
     - [ ] Empty patterns in Destructures (Let, Function) can be replaced with _
     - [ ] All empty patterns in Pattern Matches (Cases) must remain!

-}
