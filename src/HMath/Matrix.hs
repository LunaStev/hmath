-- SPDX-License-Identifier: MPL-2.0

module HMath.Matrix
    ( Matrix
    , fromList
    , toList
    , shape
    , addMatrix
    , multiply
    , transposeMatrix
    , identity
    ) where

data Matrix a = Matrix Int Int [[a]]
    deriving (Eq, Show)

fromList :: Int -> Int -> [a] -> Maybe (Matrix a)
fromList rows cols values
    | rows < 0 || cols < 0 = Nothing
    | length values /= rows * cols = Nothing
    | otherwise = Just (Matrix rows cols (split cols values))
    where
        split _ [] = []
        split n xs
            | n == 0 = []
            | otherwise =
                let (row, rest) = splitAt n xs
                in row : split n rest

toList :: Matrix a -> [a]
toList (Matrix _ _ values) = concat values

shape :: Matrix a -> (Int, Int)
shape (Matrix rows cols _) = (rows, cols)

addMatrix :: Num a => Matrix a -> Matrix a -> Maybe (Matrix a)
addMatrix (Matrix r1 c1 a) (Matrix r2 c2 b)
    | r1 /= r2 || c1 /= c2 = Nothing
    | otherwise =
        Just (Matrix r1 c1 (zipWith (zipWith (+)) a b))

transposeMatrix :: Matrix a -> Matrix a
transposeMatrix (Matrix rows cols values) =
    Matrix cols rows
        [ [values !! i !! j | i <- [0..rows - 1]]
        | j <- [0..cols - 1]
        ]

multiply :: Num a => Matrix a -> Matrix a -> Maybe (Matrix a)
multiply (Matrix r1 c1 a) b
    | c1 /= r2 = Nothing
    | otherwise = Just (Matrix r1 c2 result)
    where
        (r2, c2) = shape b
        Matrix _ _ bt = transposeMatrix b

        result =
            [ [sum (zipWith (*) row col) | col <- bt]
            | row <- a
            ]

identity :: Num a => Int -> Maybe (Matrix a)
identity n
    | n < 0 = Nothing
    | otherwise =
        Just (Matrix n n
            [ [if i == j then 1 else 0 | j <- [0..n - 1]]
            | i <- [0..n - 1]
            ])
