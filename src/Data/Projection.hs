{-# LANGUAGE ConstraintKinds       #-}
{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE GADTs                 #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE PolyKinds             #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE TypeOperators         #-}
{-# LANGUAGE UndecidableInstances  #-}

--------------------------------------------------------------------------------
-- |
-- Module      :  Data.Projection
-- Copyright   :  (c) 2014 Patrick Bahr
-- License     :  BSD3
-- Maintainer  :  Patrick Bahr <paba@di.ku.dk>
-- Stability   :  experimental
-- Portability :  non-portable (GHC Extensions)
--
-- This module provides a generic projection function 'pr' for
-- arbitrary nested binary products.
--
--------------------------------------------------------------------------------


module Data.Projection (pr, (:<)) where

import Prelude hiding (Either (..))

data Pos = Here | Left Pos | Right Pos

data RPos = NotFound | Ambiguous | Found Pos

type family Ch (l :: RPos) (r :: RPos) :: RPos where
    Ch (Found x) (Found y) = Ambiguous
    Ch Ambiguous y = Ambiguous
    Ch x Ambiguous = Ambiguous
    Ch (Found x) y = Found (Left x)
    Ch x (Found y) = Found (Right y)
    Ch x y = NotFound

type family Elem (e :: *) (p :: *) :: RPos where
    Elem e e = Found Here
    Elem e (l,r) = Ch (Elem e l) (Elem e r)
    Elem e p = NotFound

data Pointer (pos :: RPos) e p where
    Phere :: Pointer (Found Here) e e
    Pleft :: Pointer (Found pos) e p -> Pointer (Found (Left pos)) e (p,p')
    Pright :: Pointer (Found pos) e p -> Pointer (Found (Right pos)) e (p',p)

class GetPointer (pos :: RPos) e p where
    pointer :: Pointer pos e p

instance GetPointer (Found Here) e e where
    pointer = Phere

instance GetPointer (Found pos) e p => GetPointer (Found (Left pos)) e (p, p') where
    pointer = Pleft pointer

instance GetPointer (Found pos) e p => GetPointer (Found (Right pos)) e (p', p) where
    pointer = Pright pointer

pr' :: Pointer pos e p -> p -> e
pr' Phere e = e
pr' (Pleft p) (x,_) = pr' p x
pr' (Pright p) (_,y) = pr' p y


-- | The constraint @e :< p@ expresses that @e@ is a component of the
-- type @p@. That is, @p@ is formed by binary products using the type
-- @e@. The occurrence of @e@ must be unique. For example we have @Int
-- :< (Bool,(Int,Bool))@ but not @Bool :< (Bool,(Int,Bool))@.
type (e :< p) = GetPointer (Elem e p) e p

-- | This function projects the component of type @e@ out or the
-- compound value of type @p@.

pr :: forall e p . (e :< p) => p -> e
pr p = pr' (pointer :: Pointer (Elem e p) e p) p
