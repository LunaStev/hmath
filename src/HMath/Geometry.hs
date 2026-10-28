-- SPDX-License-Identifier: MPL-2.0

{- | Checked Cartesian geometry and bounded CPU reference algorithms.
Coordinates are finite with absolute value <=1e50; ND dimensions are 1..16.
Raw primitive constructors are convenient for pattern matching, so every
checked operation revalidates its inputs. Boundaries are included unless an
API returns an explicit 'Location'. Two-dimensional positive orientation is
counterclockwise; three-dimensional coordinates are right-handed.

Polygon Boolean output rings preserve hole orientation. Constrained Delaunay
constraints are noncrossing edges, not a polygon-domain/hole specification.
Spatial queries expose exact/budget-exhaustion status. Collision support APIs
operate on planar convex hulls; camera transforms follow OpenGL depth rules.
Each algorithm documents its finite reference budget in the defining module.
-}
module HMath.Geometry (
    Point2 (..),
    Point3 (..),
    PointND (..),
    point2,
    point3,
    pointND,
    Line (..),
    Ray (..),
    Segment (..),
    Plane (..),
    Triangle (..),
    Rectangle (..),
    Circle (..),
    Ellipse (..),
    Polygon (..),
    Sphere (..),
    AABB (..),
    OBB (..),
    Capsule (..),
    Cylinder (..),
    Cone (..),
    Frustum (..),
    Orientation (..),
    Location (..),
    module HMath.Geometry.Primitives,
    module HMath.Geometry.Polygon,
    module HMath.Geometry.Triangulation,
    module HMath.Geometry.Spatial,
    module HMath.Geometry.Collision,
    module HMath.Geometry.Transform,
) where

import HMath.Geometry.Collision
import HMath.Geometry.Internal
import HMath.Geometry.Polygon
import HMath.Geometry.Primitives
import HMath.Geometry.Spatial
import HMath.Geometry.Transform
import HMath.Geometry.Triangulation
