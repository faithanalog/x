Response to an issue at https://github.com/ILikePizza555/Snakey/issues/5#issuecomment-473478283

I think this can be solved by changing the Snake datatype. I'm going to use haskell for this. Disclaimer: I haven't compiled the code below, so I can't say with 100% certainty that it typechecks, but it should.

So right now you essentially have:

```haskell
newtype Snake a b = Snake { runSnake :: a -> b }

chain :: Snake a b -> Snake b c -> Snake a c
chain (Snake snakeAB) (Snake snakeBC) = Snake (snakeBC . snakeAB)
```

This is basically just a wrapper around function composition. I think that what you actually want is Either. Consider:

```haskell
data Either r a = Left r | Right a

-- I'm omitting the requisite Functor and Applicative instances because I
-- don't feel like writing them.
instance Monad (Either l) where
    (>>=) :: Either r a -> (a -> Either r b) -> Either r b
    Left r >>= f = Left r
    Right a >>= f = f a

-- For convenience, here's an equivalent to Snake & Chain
type Snake r a b = a -> Either r b

chain :: Snake r a b -> Snake r b c -> Snake r a c
chain snakeAB snakeBC =
    \a -> snakeAB a >>= snakeBC

-- Which, when you expand (>>=) looks like
chain snakeAB snakeBC =
    \a -> case snakeAB a of
        Left r -> Left r
        Right b -> snakeBC b

-- And then our identity function
snake :: Snake r a a
snake = \a -> Right a

-- And a way to lift a normal function into a snake
toSnake :: (a -> b) -> Snake r a b
toSnake f = \a -> Right (f a)
```


Now we can allow a chain to terminate early by returning the left value. We'll just leave it as () for now.

```haskell
type Route = Snake () Context Response
```

And let's make a function that lets us combine two snakes, such that:
- If the left snake returns a response, that response is returned
- If not, but the right snake returns a response, that response is returned
- Otherwise, `()` is returned

```haskell
-- This is actually mappend from monoid, AKA the <> operator AKA concat
concatRoute :: Route -> Route -> Route
concatRoute leftSnake rightSnake =
    \context ->
        case leftSnake context of
            Left _ -> rightSnake context
            Right response -> Right response

concatAllRoutes :: [Route] -> Route
concatAllRoutes (r:routes) = concatRoute r (concatAllRoutes routes)
```

Thus, applySnakes can run the concatenated routes, and return a 404 response if none match. The first matching route stops any other routes from running.

```haskell
-- Let's make a basic 404 response, assuming that
-- withResponseCode :: Int -> Response -> Response
-- since I don't know how the library works
do404 :: Context -> Response
do404 context =
    withResponseCode
        404
        (textResponse
            ("Lol couldn't find " ++ show (uri context)))

applySnakes :: [Route] -> Context -> Response
applySnakes routes =
    \context ->
        case (concatAllRoutes routes) context of
            Left _ -> do404 context
            Right response -> response 

app :: [Route]
app = [
    snake
        `chain` bite "GET" "/"
        `chain` textResponse "Hello World!"
]

sendResponse :: Response -> IO ()
sendResponse = ???

server = \context -> sendResponse (applySnakes app)
```


This isn't too terrible to translate to typescript, and allows your routes to remain stateless like they are now.

I'm not going to fully implement it, but you could go on from here to add termination reasons for things like access control

```haskell
type Route = Snake TerminationReason Context Response

data TerminationReason = NoMatch | Unauthorized

-- Implement this with special handling on Unauthorized
applySnakes :: [Route] -> Context -> Response
```