# Geometry bindings

`from hmath import geometry` calls the original checked geometry algorithms. C includes `hmath_geometry.h`. Coordinates retain their finite1e50 cap, ND dimension1..16 bounds, exact Rational orientation/incircle predicates, source algorithm budgets, tie order and Double outputs. Raw public constructors retain their unchecked behavior; checked operations validate them without adapter changes.

Objects are immutable owned [structured values](values.md); inputs are borrowed for a synchronous call and success transfers one output reference. Outputs stay untouched on failure. Each live owner pins the runtime. Independent readers retain their own references; original MathError/status11 includes its complete constructor and payload. Cancellation is checked before entry.

Use `parts(value)` or `value.parts` for a public data constructor: it returns `(constructor_name, tuple_of_fields)` with typed child owners. A child remains valid after its parent closes. `value.coordinates` returns coordinates for Point2/Point3/PointND. Abstract PointCloud/SpatialIndex remain abstract; their original query functions are available. `describe(value)` exposes the original Show representation for inspection, without parsing or dispatching mathematics through text.

`line_plane_intersection` and `plane_intersection` return `(outer_present, inner_optional)`: `(False, None)` is no intersection, `(True, None)` is coincidence, `(True, value)` is one intersection. This preserves all three source `Maybe (Maybe a)` states. `incircle` returns `Ordering.LT/EQ/GT` (C Haskell-Int values -1/0/1). Indexed triangles remain tuples of three zero-based original input indices. Matrix operations exchange actual shared `Matrix Double` objects.

Polygon Boolean rings retain exterior/hole orientation. Constraints in Delaunay triangulation do not become a polygon/hole specification. Nearest-neighbor results keep original IDs, distance/ID tie order and explicit budget/exhaustive fields. Collision/penetration error estimates retain their source meaning; transforms retain the documented OpenGL depth conventions.

The existing hamming/jaccard compatibility functions expose Float/Double numeric variants; they do not claim arbitrary user-defined Haskell Eq instances.

## `penetration`

`geometry.penetration(number, point2, number2, count)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Double -> Point2 -> Double -> Int -> Penetration
```

```c
hmath_status hmath_geometry_penetration(hmath_context *context, const hmath_value *number, const hmath_value *point2, const hmath_value *number2, const hmath_value *count, hmath_value **out);
```

## `epa`

`geometry.epa(count, number, values, values2)`

 Expanding polytope penetration estimate. The tolerance is an absolute support-gap stopping threshold, positive finite and <=1e50. 

```haskell
Int -> Double -> [Point2] -> [Point2] -> Either MathError (Maybe Penetration)
```

```c
hmath_status hmath_geometry_epa(hmath_context *context, const hmath_value *count, const hmath_value *number, const hmath_value *values, const hmath_value *values2, hmath_value **out);
```

## `gjk`

`geometry.gjk(count, values, values2)`

Convex intersection by Gilbert-Johnson-Keerthi support/simplex iterations.

```haskell
Int -> [Point2] -> [Point2] -> Either MathError Bool
```

```c
hmath_status hmath_geometry_gjk(hmath_context *context, const hmath_value *count, const hmath_value *values, const hmath_value *values2, hmath_value **out);
```

## `penetration_depth`

`geometry.penetration_depth(penetration)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Penetration -> Double
```

```c
hmath_status hmath_geometry_penetration_depth(hmath_context *context, const hmath_value *penetration, hmath_value **out);
```

## `penetration_error`

`geometry.penetration_error(penetration)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Penetration -> Double
```

```c
hmath_status hmath_geometry_penetration_error(hmath_context *context, const hmath_value *penetration, hmath_value **out);
```

## `penetration_iterations`

`geometry.penetration_iterations(penetration)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Penetration -> Int
```

```c
hmath_status hmath_geometry_penetration_iterations(hmath_context *context, const hmath_value *penetration, hmath_value **out);
```

## `penetration_normal`

`geometry.penetration_normal(penetration)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Penetration -> Point2
```

```c
hmath_status hmath_geometry_penetration_normal(hmath_context *context, const hmath_value *penetration, hmath_value **out);
```

## `separating_axis`

`geometry.separating_axis(values, values2)`

 Separating-axis collision and minimum overlap for convex polygons. Shapes must have nonzero area; containment depth uses the distance to the nearer separating interval endpoint, rather than only the interval intersection. 

```haskell
[Point2] -> [Point2] -> Either MathError (Maybe Penetration)
```

```c
hmath_status hmath_geometry_separating_axis(hmath_context *context, const hmath_value *values, const hmath_value *values2, hmath_value **out);
```

## `aabb`

`geometry.aabb(point_nd, point_nd2)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
PointND -> PointND -> AABB
```

```c
hmath_status hmath_geometry_aabb(hmath_context *context, const hmath_value *point_nd, const hmath_value *point_nd2, hmath_value **out);
```

## `boundary`

`geometry.boundary()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Location
```

```c
hmath_status hmath_geometry_boundary(hmath_context *context, hmath_value **out);
```

## `capsule`

`geometry.capsule(point3, point32, number)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Point3 -> Point3 -> Double -> Capsule
```

```c
hmath_status hmath_geometry_capsule(hmath_context *context, const hmath_value *point3, const hmath_value *point32, const hmath_value *number, hmath_value **out);
```

## `circle`

`geometry.circle(point2, number)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Point2 -> Double -> Circle
```

```c
hmath_status hmath_geometry_circle(hmath_context *context, const hmath_value *point2, const hmath_value *number, hmath_value **out);
```

## `clockwise`

`geometry.clockwise()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Orientation
```

```c
hmath_status hmath_geometry_clockwise(hmath_context *context, hmath_value **out);
```

## `collinear`

`geometry.collinear()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Orientation
```

```c
hmath_status hmath_geometry_collinear(hmath_context *context, hmath_value **out);
```

## `cone`

`geometry.cone(point3, point32, number)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Point3 -> Point3 -> Double -> Cone
```

```c
hmath_status hmath_geometry_cone(hmath_context *context, const hmath_value *point3, const hmath_value *point32, const hmath_value *number, hmath_value **out);
```

## `counterclockwise`

`geometry.counterclockwise()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Orientation
```

```c
hmath_status hmath_geometry_counterclockwise(hmath_context *context, hmath_value **out);
```

## `cylinder`

`geometry.cylinder(point3, point32, number)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Point3 -> Point3 -> Double -> Cylinder
```

```c
hmath_status hmath_geometry_cylinder(hmath_context *context, const hmath_value *point3, const hmath_value *point32, const hmath_value *number, hmath_value **out);
```

## `ellipse`

`geometry.ellipse(point2, number, number2, number3)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Point2 -> Double -> Double -> Double -> Ellipse
```

```c
hmath_status hmath_geometry_ellipse(hmath_context *context, const hmath_value *point2, const hmath_value *number, const hmath_value *number2, const hmath_value *number3, hmath_value **out);
```

## `frustum`

`geometry.frustum(values)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
[Plane] -> Frustum
```

```c
hmath_status hmath_geometry_frustum(hmath_context *context, const hmath_value *values, hmath_value **out);
```

## `inside`

`geometry.inside()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Location
```

```c
hmath_status hmath_geometry_inside(hmath_context *context, hmath_value **out);
```

## `line`

`geometry.line(point_nd, point_nd2)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
PointND -> PointND -> Line
```

```c
hmath_status hmath_geometry_line(hmath_context *context, const hmath_value *point_nd, const hmath_value *point_nd2, hmath_value **out);
```

## `obb`

`geometry.obb(point3, values, point32)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Point3 -> [Point3] -> Point3 -> OBB
```

```c
hmath_status hmath_geometry_obb(hmath_context *context, const hmath_value *point3, const hmath_value *values, const hmath_value *point32, hmath_value **out);
```

## `outside`

`geometry.outside()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Location
```

```c
hmath_status hmath_geometry_outside(hmath_context *context, hmath_value **out);
```

## `p2`

`geometry.p2(number, number2)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Double -> Double -> Point2
```

```c
hmath_status hmath_geometry_p2(hmath_context *context, const hmath_value *number, const hmath_value *number2, hmath_value **out);
```

## `p3`

`geometry.p3(number, number2, number3)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Double -> Double -> Double -> Point3
```

```c
hmath_status hmath_geometry_p3(hmath_context *context, const hmath_value *number, const hmath_value *number2, const hmath_value *number3, hmath_value **out);
```

## `plane`

`geometry.plane(point3, number)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Point3 -> Double -> Plane
```

```c
hmath_status hmath_geometry_plane(hmath_context *context, const hmath_value *point3, const hmath_value *number, hmath_value **out);
```

## `point_nd_raw`

`geometry.point_nd(values)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
[Double] -> PointND
```

```c
hmath_status hmath_geometry_point_nd_raw(hmath_context *context, const hmath_value *values, hmath_value **out);
```

## `polygon`

`geometry.polygon(values)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
[Point2] -> Polygon
```

```c
hmath_status hmath_geometry_polygon(hmath_context *context, const hmath_value *values, hmath_value **out);
```

## `ray`

`geometry.ray(point3, point32)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Point3 -> Point3 -> Ray
```

```c
hmath_status hmath_geometry_ray(hmath_context *context, const hmath_value *point3, const hmath_value *point32, hmath_value **out);
```

## `rectangle`

`geometry.rectangle(point2, point22)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Point2 -> Point2 -> Rectangle
```

```c
hmath_status hmath_geometry_rectangle(hmath_context *context, const hmath_value *point2, const hmath_value *point22, hmath_value **out);
```

## `segment`

`geometry.segment(point_nd, point_nd2)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
PointND -> PointND -> Segment
```

```c
hmath_status hmath_geometry_segment(hmath_context *context, const hmath_value *point_nd, const hmath_value *point_nd2, hmath_value **out);
```

## `sphere`

`geometry.sphere(point3, number)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Point3 -> Double -> Sphere
```

```c
hmath_status hmath_geometry_sphere(hmath_context *context, const hmath_value *point3, const hmath_value *number, hmath_value **out);
```

## `triangle`

`geometry.triangle(point2, point22, point23)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Point2 -> Point2 -> Point2 -> Triangle
```

```c
hmath_status hmath_geometry_triangle(hmath_context *context, const hmath_value *point2, const hmath_value *point22, const hmath_value *point23, hmath_value **out);
```

## `point2`

`geometry.point2(number, number2)`

 Given x,y, construct Point2 after bounded finite-coordinate validation. Invalid values return DomainError. 

```haskell
Double -> Double -> Either MathError Point2
```

```c
hmath_status hmath_geometry_point2(hmath_context *context, const hmath_value *number, const hmath_value *number2, hmath_value **out);
```

## `point3`

`geometry.point3(number, number2, number3)`

 Given x,y,z, construct Point3 after bounded finite-coordinate validation. Invalid values return DomainError. 

```haskell
Double -> Double -> Double -> Either MathError Point3
```

```c
hmath_status hmath_geometry_point3(hmath_context *context, const hmath_value *number, const hmath_value *number2, const hmath_value *number3, hmath_value **out);
```

## `point_nd`

`geometry.point_nd(values)`

 Construct a checked ND point from 1..16 bounded finite coordinates. Invalid dimension/value returns DomainError. 

```haskell
[Double] -> Either MathError PointND
```

```c
hmath_status hmath_geometry_point_nd(hmath_context *context, const hmath_value *values, hmath_value **out);
```

## `difference`

`geometry.difference()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
BooleanOperation
```

```c
hmath_status hmath_geometry_difference(hmath_context *context, hmath_value **out);
```

## `gift_wrapping`

`geometry.gift_wrapping()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
HullAlgorithm
```

```c
hmath_status hmath_geometry_gift_wrapping(hmath_context *context, hmath_value **out);
```

## `graham_scan`

`geometry.graham_scan()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
HullAlgorithm
```

```c
hmath_status hmath_geometry_graham_scan(hmath_context *context, hmath_value **out);
```

## `intersection`

`geometry.intersection()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
BooleanOperation
```

```c
hmath_status hmath_geometry_intersection(hmath_context *context, hmath_value **out);
```

## `monotone_chain`

`geometry.monotone_chain()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
HullAlgorithm
```

```c
hmath_status hmath_geometry_monotone_chain(hmath_context *context, hmath_value **out);
```

## `quickhull`

`geometry.quickhull()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
HullAlgorithm
```

```c
hmath_status hmath_geometry_quickhull(hmath_context *context, hmath_value **out);
```

## `union`

`geometry.union()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
BooleanOperation
```

```c
hmath_status hmath_geometry_union(hmath_context *context, hmath_value **out);
```

## `clip_polygon`

`geometry.clip_polygon(polygon, polygon2)`

 Sutherland-Hodgman clipping against a convex CCW/clockwise clip polygon. Output may be empty; nonconvex clippers fail instead of silently corrupting output. 

```haskell
Polygon -> Polygon -> Either MathError [Point2]
```

```c
hmath_status hmath_geometry_clip_polygon(hmath_context *context, const hmath_value *polygon, const hmath_value *polygon2, hmath_value **out);
```

## `convex_hull`

`geometry.convex_hull(hull_algorithm, values)`

Convex hull with at most 4096 input points. Exact orientation breaks degeneracies.

```haskell
HullAlgorithm -> [Point2] -> Either MathError [Point2]
```

```c
hmath_status hmath_geometry_convex_hull(hmath_context *context, const hmath_value *hull_algorithm, const hmath_value *values, hmath_value **out);
```

## `minimum_bounding_circle`

`geometry.minimum_bounding_circle(values)`

 Deterministic incremental minimum enclosing circle, O(n^3), at most 256 points. Each violated boundary introduces a 1-, 2-, or 3-point support. 

```haskell
[Point2] -> Either MathError Circle
```

```c
hmath_status hmath_geometry_minimum_bounding_circle(hmath_context *context, const hmath_value *values, hmath_value **out);
```

## `minimum_bounding_rectangle`

`geometry.minimum_bounding_rectangle(values)`

 Minimum-area oriented enclosing rectangle. Testing every hull edge uses the rotating-calipers extremal-orientation theorem; the reference scans all vertices for each orientation (O(h^2)), at most 4096 points. 

```haskell
[Point2] -> Either MathError [Point2]
```

```c
hmath_status hmath_geometry_minimum_bounding_rectangle(hmath_context *context, const hmath_value *values, hmath_value **out);
```

## `minkowski_sum`

`geometry.minkowski_sum(values, values2)`

 Convex Minkowski sum, via pairwise sums followed by a hull. Nonconvex inputs are deliberately convexified; at most 64 vertices per operand. 

```haskell
[Point2] -> [Point2] -> Either MathError [Point2]
```

```c
hmath_status hmath_geometry_minkowski_sum(hmath_context *context, const hmath_value *values, const hmath_value *values2, hmath_value **out);
```

## `polygon_area`

`geometry.polygon_area(polygon)`

Unsigned simple polygon area.

```haskell
Polygon -> Either MathError Double
```

```c
hmath_status hmath_geometry_polygon_area(hmath_context *context, const hmath_value *polygon, hmath_value **out);
```

## `polygon_boolean`

`geometry.polygon_boolean(boolean_operation, polygon, polygon2)`

 Exact edge-arrangement Boolean. Empty output is allowed, including an intersection that consists only of points/segments (zero-area components). 

```haskell
BooleanOperation -> Polygon -> Polygon -> Either MathError [Polygon]
```

```c
hmath_status hmath_geometry_polygon_boolean(hmath_context *context, const hmath_value *boolean_operation, const hmath_value *polygon, const hmath_value *polygon2, hmath_value **out);
```

## `polygon_centroid`

`geometry.polygon_centroid(polygon)`

Area-weighted centroid; works for nonconvex simple polygons.

```haskell
Polygon -> Either MathError Point2
```

```c
hmath_status hmath_geometry_polygon_centroid(hmath_context *context, const hmath_value *polygon, hmath_value **out);
```

## `shoelace`

`geometry.shoelace(polygon)`

Signed shoelace area; clockwise polygons have negative area.

```haskell
Polygon -> Either MathError Double
```

```c
hmath_status hmath_geometry_shoelace(hmath_context *context, const hmath_value *polygon, hmath_value **out);
```

## `chebyshev`

`geometry.chebyshev()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Metric
```

```c
hmath_status hmath_geometry_chebyshev(hmath_context *context, hmath_value **out);
```

## `circle_points`

`geometry.circle_points(values)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
[Point2] -> CircleIntersection
```

```c
hmath_status hmath_geometry_circle_points(hmath_context *context, const hmath_value *values, hmath_value **out);
```

## `coincident_circles`

`geometry.coincident_circles()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
CircleIntersection
```

```c
hmath_status hmath_geometry_coincident_circles(hmath_context *context, hmath_value **out);
```

## `coincident_line`

`geometry.coincident_line()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Intersection2
```

```c
hmath_status hmath_geometry_coincident_line(hmath_context *context, hmath_value **out);
```

## `disjoint_circles`

`geometry.disjoint_circles()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
CircleIntersection
```

```c
hmath_status hmath_geometry_disjoint_circles(hmath_context *context, hmath_value **out);
```

## `euclidean`

`geometry.euclidean()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Metric
```

```c
hmath_status hmath_geometry_euclidean(hmath_context *context, hmath_value **out);
```

## `intersection_point`

`geometry.intersection_point(point2)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Point2 -> Intersection2
```

```c
hmath_status hmath_geometry_intersection_point(hmath_context *context, const hmath_value *point2, hmath_value **out);
```

## `manhattan`

`geometry.manhattan()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Metric
```

```c
hmath_status hmath_geometry_manhattan(hmath_context *context, hmath_value **out);
```

## `minkowski`

`geometry.minkowski(number)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Double -> Metric
```

```c
hmath_status hmath_geometry_minkowski(hmath_context *context, const hmath_value *number, hmath_value **out);
```

## `no_intersection`

`geometry.no_intersection()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Intersection2
```

```c
hmath_status hmath_geometry_no_intersection(hmath_context *context, hmath_value **out);
```

## `overlap_segment`

`geometry.overlap_segment(point2, point22)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Point2 -> Point2 -> Intersection2
```

```c
hmath_status hmath_geometry_overlap_segment(hmath_context *context, const hmath_value *point2, const hmath_value *point22, hmath_value **out);
```

## `box_contains`

`geometry.box_contains(aabb, point_nd)`

Closed axis-aligned box containment.

```haskell
AABB -> PointND -> Either MathError Bool
```

```c
hmath_status hmath_geometry_box_contains(hmath_context *context, const hmath_value *aabb, const hmath_value *point_nd, hmath_value **out);
```

## `box_sdf`

`geometry.box_sdf(aabb, point_nd)`

Axis-aligned box exact signed Euclidean distance in 1..16 dimensions.

```haskell
AABB -> PointND -> Either MathError Double
```

```c
hmath_status hmath_geometry_box_sdf(hmath_context *context, const hmath_value *aabb, const hmath_value *point_nd, hmath_value **out);
```

## `capsule_sdf`

`geometry.capsule_sdf(capsule, point3)`

Capsule distance from its closed axis minus radius.

```haskell
Capsule -> Point3 -> Either MathError Double
```

```c
hmath_status hmath_geometry_capsule_sdf(hmath_context *context, const hmath_value *capsule, const hmath_value *point3, hmath_value **out);
```

## `circle_intersection`

`geometry.circle_intersection(circle, circle2)`

 Given two circles, return DisjointCircles, CoincidentCircles, or CirclePoints for their intersection. Require valid finite centers and nonnegative bounded radii. Tangency yields one point; identical zero-radius circles yield their single center. 

```haskell
Circle -> Circle -> Either MathError CircleIntersection
```

```c
hmath_status hmath_geometry_circle_intersection(hmath_context *context, const hmath_value *circle, const hmath_value *circle2, hmath_value **out);
```

## `circumcenter`

`geometry.circumcenter(triangle)`

Circumcenter, obtained from exact rational perpendicular-bisector equations.

```haskell
Triangle -> Either MathError Point2
```

```c
hmath_status hmath_geometry_circumcenter(hmath_context *context, const hmath_value *triangle, hmath_value **out);
```

## `cone_sdf`

`geometry.cone_sdf(cone, point3)`

Exact finite-cone distance by reducing to its radial/axial cross-section.

```haskell
Cone -> Point3 -> Either MathError Double
```

```c
hmath_status hmath_geometry_cone_sdf(hmath_context *context, const hmath_value *cone, const hmath_value *point3, hmath_value **out);
```

## `cosine_distance`

`geometry.cosine_distance(point_nd, point_nd2)`

One minus cosine similarity; zero vectors are undefined.

```haskell
PointND -> PointND -> Either MathError Double
```

```c
hmath_status hmath_geometry_cosine_distance(hmath_context *context, const hmath_value *point_nd, const hmath_value *point_nd2, hmath_value **out);
```

## `cylinder_sdf`

`geometry.cylinder_sdf(cylinder, point3)`

Exact capped finite-cylinder signed distance.

```haskell
Cylinder -> Point3 -> Either MathError Double
```

```c
hmath_status hmath_geometry_cylinder_sdf(hmath_context *context, const hmath_value *cylinder, const hmath_value *point3, hmath_value **out);
```

## `distance`

`geometry.distance(metric, point_nd, point_nd2)`

Euclidean, L1, Linfinity, or scaled Lp distance.

```haskell
Metric -> PointND -> PointND -> Either MathError Double
```

```c
hmath_status hmath_geometry_distance(hmath_context *context, const hmath_value *metric, const hmath_value *point_nd, const hmath_value *point_nd2, hmath_value **out);
```

## `ellipse_contains`

`geometry.ellipse_contains(ellipse, point2)`

Closed ellipse containment after rotation to its principal axes.

```haskell
Ellipse -> Point2 -> Either MathError Bool
```

```c
hmath_status hmath_geometry_ellipse_contains(hmath_context *context, const hmath_value *ellipse, const hmath_value *point2, hmath_value **out);
```

## `hausdorff_distance`

`geometry.hausdorff_distance(values, values2)`

Symmetric Hausdorff distance on two nonempty finite clouds, at most 1024 each.

```haskell
[PointND] -> [PointND] -> Either MathError Double
```

```c
hmath_status hmath_geometry_hausdorff_distance(hmath_context *context, const hmath_value *values, const hmath_value *values2, hmath_value **out);
```

## `incenter`

`geometry.incenter(triangle)`

Incenter weighted by opposite side lengths.

```haskell
Triangle -> Either MathError Point2
```

```c
hmath_status hmath_geometry_incenter(hmath_context *context, const hmath_value *triangle, hmath_value **out);
```

## `incircle`

`geometry.incircle(point2, point22, point23, point24)`

 Exact in-circle sign, orientation-independent: positive means inside. A collinear defining triangle is rejected. 

```haskell
Point2 -> Point2 -> Point2 -> Point2 -> Either MathError Ordering
```

```c
hmath_status hmath_geometry_incircle(hmath_context *context, const hmath_value *point2, const hmath_value *point22, const hmath_value *point23, const hmath_value *point24, hmath_value **out);
```

## `line_intersection`

`geometry.line_intersection(point2, point22, point23, point24)`

Infinite-line intersection from origins and nonzero direction vectors.

```haskell
Point2 -> Point2 -> Point2 -> Point2 -> Either MathError Intersection2
```

```c
hmath_status hmath_geometry_line_intersection(hmath_context *context, const hmath_value *point2, const hmath_value *point22, const hmath_value *point23, const hmath_value *point24, hmath_value **out);
```

## `line_plane_intersection`

`geometry.line_plane_intersection(line, plane)`

 Line/plane result: Nothing parallel/disjoint, Just Nothing coincident, Just (Just p) a unique intersection. The line must have dimension three. 

```haskell
Line -> Plane -> Either MathError (Maybe (Maybe Point3))
```

```c
hmath_status hmath_geometry_line_plane_intersection(hmath_context *context, const hmath_value *line, const hmath_value *plane, hmath_value **out);
```

## `mahalanobis_distance`

`geometry.mahalanobis_distance(values, point_nd, point_nd2)`

 Mahalanobis distance using a checked symmetric positive-definite covariance. A Cholesky triangular solve avoids an explicit inverse. 

```haskell
[[Double]] -> PointND -> PointND -> Either MathError Double
```

```c
hmath_status hmath_geometry_mahalanobis_distance(hmath_context *context, const hmath_value *values, const hmath_value *point_nd, const hmath_value *point_nd2, hmath_value **out);
```

## `obb_sdf`

`geometry.obb_sdf(obb, point3)`

Oriented box distance after validating its orthonormal axes.

```haskell
OBB -> Point3 -> Either MathError Double
```

```c
hmath_status hmath_geometry_obb_sdf(hmath_context *context, const hmath_value *obb, const hmath_value *point3, hmath_value **out);
```

## `orientation`

`geometry.orientation(point2, point22, point23)`

Exact orientation of the represented finite Double coordinates.

```haskell
Point2 -> Point2 -> Point2 -> Either MathError Orientation
```

```c
hmath_status hmath_geometry_orientation(hmath_context *context, const hmath_value *point2, const hmath_value *point22, const hmath_value *point23, hmath_value **out);
```

## `plane_intersection`

`geometry.plane_intersection(plane, plane2)`

 Plane intersection: same nested convention as linePlaneIntersection, with the unique intersection represented by a line. 

```haskell
Plane -> Plane -> Either MathError (Maybe (Maybe Line))
```

```c
hmath_status hmath_geometry_plane_intersection(hmath_context *context, const hmath_value *plane, const hmath_value *plane2, hmath_value **out);
```

## `point_line_distance`

`geometry.point_line_distance(point_nd, line)`

Distance to an infinite line; a zero direction is an error.

```haskell
PointND -> Line -> Either MathError Double
```

```c
hmath_status hmath_geometry_point_line_distance(hmath_context *context, const hmath_value *point_nd, const hmath_value *line, hmath_value **out);
```

## `point_plane_distance`

`geometry.point_plane_distance(point3, plane)`

Unsigned perpendicular plane distance.

```haskell
Point3 -> Plane -> Either MathError Double
```

```c
hmath_status hmath_geometry_point_plane_distance(hmath_context *context, const hmath_value *point3, const hmath_value *plane, hmath_value **out);
```

## `point_segment_distance`

`geometry.point_segment_distance(point_nd, segment)`

Distance to a closed segment, including a zero-length segment.

```haskell
PointND -> Segment -> Either MathError Double
```

```c
hmath_status hmath_geometry_point_segment_distance(hmath_context *context, const hmath_value *point_nd, const hmath_value *segment, hmath_value **out);
```

## `polygon_location`

`geometry.polygon_location(polygon, point2)`

Simple polygon position, with boundary separate from interior.

```haskell
Polygon -> Point2 -> Either MathError Location
```

```c
hmath_status hmath_geometry_polygon_location(hmath_context *context, const hmath_value *polygon, const hmath_value *point2, hmath_value **out);
```

## `ray_box`

`geometry.ray_box(ray, aabb)`

Slab intersection interval [entry,exit], clipped to the ray t>=0.

```haskell
Ray -> AABB -> Either MathError (Maybe (Double, Double))
```

```c
hmath_status hmath_geometry_ray_box(hmath_context *context, const hmath_value *ray, const hmath_value *aabb, hmath_value **out);
```

## `ray_sphere`

`geometry.ray_sphere(ray, sphere)`

Ray-sphere near/far nonnegative parameters; tangent gives equal roots.

```haskell
Ray -> Sphere -> Either MathError (Maybe (Double, Double))
```

```c
hmath_status hmath_geometry_ray_sphere(hmath_context *context, const hmath_value *ray, const hmath_value *sphere, hmath_value **out);
```

## `ray_triangle`

`geometry.ray_triangle(ray, tuple_value)`

 Moller-Trumbore ray intersection; coplanar rays return Nothing because their hit set is not a unique transverse surface crossing. Degenerate triangles fail. 

```haskell
Ray -> (Point3, Point3, Point3) -> Either MathError (Maybe Double)
```

```c
hmath_status hmath_geometry_ray_triangle(hmath_context *context, const hmath_value *ray, const hmath_value *tuple_value, hmath_value **out);
```

## `segment_intersection`

`geometry.segment_intersection(point2, point22, point23, point24)`

Closed segment intersection with exact degeneracy predicates.

```haskell
Point2 -> Point2 -> Point2 -> Point2 -> Either MathError Intersection2
```

```c
hmath_status hmath_geometry_segment_intersection(hmath_context *context, const hmath_value *point2, const hmath_value *point22, const hmath_value *point23, const hmath_value *point24, hmath_value **out);
```

## `sphere_contains`

`geometry.sphere_contains(sphere, point3)`

Closed sphere containment.

```haskell
Sphere -> Point3 -> Either MathError Bool
```

```c
hmath_status hmath_geometry_sphere_contains(hmath_context *context, const hmath_value *sphere, const hmath_value *point3, hmath_value **out);
```

## `sphere_sdf`

`geometry.sphere_sdf(sphere, point3)`

Sphere signed distance (negative inside).

```haskell
Sphere -> Point3 -> Either MathError Double
```

```c
hmath_status hmath_geometry_sphere_sdf(hmath_context *context, const hmath_value *sphere, const hmath_value *point3, hmath_value **out);
```

## `triangle_barycentric`

`geometry.triangle_barycentric(triangle, point2)`

Weights (a,b,c) summing to one; valid outside the triangle as well.

```haskell
Triangle -> Point2 -> Either MathError [Double]
```

```c
hmath_status hmath_geometry_triangle_barycentric(hmath_context *context, const hmath_value *triangle, const hmath_value *point2, hmath_value **out);
```

## `triangle_intersection`

`geometry.triangle_intersection(triangle, triangle2)`

Closed triangle overlap polygon, including isolated tangencies as vertices.

```haskell
Triangle -> Triangle -> Either MathError [Point2]
```

```c
hmath_status hmath_geometry_triangle_intersection(hmath_context *context, const hmath_value *triangle, const hmath_value *triangle2, hmath_value **out);
```

## `triangle_location`

`geometry.triangle_location(triangle, point2)`

Triangle position using exact orientation signs.

```haskell
Triangle -> Point2 -> Either MathError Location
```

```c
hmath_status hmath_geometry_triangle_location(hmath_context *context, const hmath_value *triangle, const hmath_value *point2, hmath_value **out);
```

## `bvh`

`geometry.bvh()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
SpatialKind
```

```c
hmath_status hmath_geometry_bvh(hmath_context *context, hmath_value **out);
```

## `ball_tree`

`geometry.ball_tree()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
SpatialKind
```

```c
hmath_status hmath_geometry_ball_tree(hmath_context *context, hmath_value **out);
```

## `kd_tree`

`geometry.kd_tree()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
SpatialKind
```

```c
hmath_status hmath_geometry_kd_tree(hmath_context *context, hmath_value **out);
```

## `neighbor_query`

`geometry.neighbor_query(values, count, flag)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
[(Int, Double)] -> Int -> Bool -> NeighborQuery
```

```c
hmath_status hmath_geometry_neighbor_query(hmath_context *context, const hmath_value *values, const hmath_value *count, const hmath_value *flag, hmath_value **out);
```

## `octree`

`geometry.octree()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
SpatialKind
```

```c
hmath_status hmath_geometry_octree(hmath_context *context, hmath_value **out);
```

## `quadtree`

`geometry.quadtree()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
SpatialKind
```

```c
hmath_status hmath_geometry_quadtree(hmath_context *context, hmath_value **out);
```

## `r_tree`

`geometry.r_tree()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
SpatialKind
```

```c
hmath_status hmath_geometry_r_tree(hmath_context *context, hmath_value **out);
```

## `spatial_hash`

`geometry.spatial_hash(number)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Double -> SpatialKind
```

```c
hmath_status hmath_geometry_spatial_hash(hmath_context *context, const hmath_value *number, hmath_value **out);
```

## `build_spatial_index`

`geometry.build_spatial_index(spatial_kind, point_cloud)`

 Build the named structure. RTree uses sort-tile-recursive leaf packing (fanout 8); BVH splits longest-axis medians; quadrant trees split cells at their midplanes with a depth limit of 64 for coincident/near-coincident data. 

```haskell
SpatialKind -> PointCloud -> Either MathError SpatialIndex
```

```c
hmath_status hmath_geometry_build_spatial_index(hmath_context *context, const hmath_value *spatial_kind, const hmath_value *point_cloud, hmath_value **out);
```

## `cloud_points`

`geometry.cloud_points(point_cloud)`

Original cloud observations.

```haskell
PointCloud -> [PointND]
```

```c
hmath_status hmath_geometry_cloud_points(hmath_context *context, const hmath_value *point_cloud, hmath_value **out);
```

## `nearest_query`

`geometry.nearest_query(count, count2, spatial_index, point_nd)`

 Given neighbor count k, positive leaf budget, index, then query point, search for nearest neighbors. Require matching finite coordinate dimension and 1<=k<=65536. The result reports neighbors, visited leaves and whether search was exhaustive; an exhausted budget is not an exact-neighbor guarantee. 

```haskell
Int -> Int -> SpatialIndex -> PointND -> Either MathError NeighborQuery
```

```c
hmath_status hmath_geometry_nearest_query(hmath_context *context, const hmath_value *count, const hmath_value *count2, const hmath_value *spatial_index, const hmath_value *point_nd, hmath_value **out);
```

## `point_cloud`

`geometry.point_cloud(values)`

Construct a nonempty cloud of at most 65536 points, with consistent dimensions.

```haskell
[PointND] -> Either MathError PointCloud
```

```c
hmath_status hmath_geometry_point_cloud(hmath_context *context, const hmath_value *values, hmath_value **out);
```

## `query_exhaustive`

`geometry.query_exhaustive(neighbor_query)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
NeighborQuery -> Bool
```

```c
hmath_status hmath_geometry_query_exhaustive(hmath_context *context, const hmath_value *neighbor_query, hmath_value **out);
```

## `query_leaves`

`geometry.query_leaves(neighbor_query)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
NeighborQuery -> Int
```

```c
hmath_status hmath_geometry_query_leaves(hmath_context *context, const hmath_value *neighbor_query, hmath_value **out);
```

## `query_neighbors`

`geometry.query_neighbors(neighbor_query)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
NeighborQuery -> [(Int, Double)]
```

```c
hmath_status hmath_geometry_query_neighbors(hmath_context *context, const hmath_value *neighbor_query, hmath_value **out);
```

## `radius_query`

`geometry.radius_query(spatial_index, point_nd, number)`

Exact closed radius query; uses the index range query then Euclidean filtering.

```haskell
SpatialIndex -> PointND -> Double -> Either MathError [Int]
```

```c
hmath_status hmath_geometry_radius_query(hmath_context *context, const hmath_value *spatial_index, const hmath_value *point_nd, const hmath_value *number, hmath_value **out);
```

## `range_query`

`geometry.range_query(spatial_index, aabb)`

 Closed range search, sorted original IDs. Hash queries inspect occupied bucket bounds, avoiding an unbounded Cartesian enumeration of empty cells. 

```haskell
SpatialIndex -> AABB -> Either MathError [Int]
```

```c
hmath_status hmath_geometry_range_query(hmath_context *context, const hmath_value *spatial_index, const hmath_value *aabb, hmath_value **out);
```

## `affine_transform`

`geometry.affine_transform(matrix, point_nd)`

Construct an affine matrix [linear,translation;0,1].

```haskell
Matrix Double -> PointND -> Either MathError (Matrix Double)
```

```c
hmath_status hmath_geometry_affine_transform(hmath_context *context, const hmath_value *matrix, const hmath_value *point_nd, hmath_value **out);
```

## `apply_transform`

`geometry.apply_transform(matrix, point_nd)`

Apply an affine or projective matrix and divide by homogeneous w.

```haskell
Matrix Double -> PointND -> Either MathError PointND
```

```c
hmath_status hmath_geometry_apply_transform(hmath_context *context, const hmath_value *matrix, const hmath_value *point_nd, hmath_value **out);
```

## `compose_transforms`

`geometry.compose_transforms(matrix, matrix2)`

Checked matrix composition; projective and affine matrices may be mixed.

```haskell
Matrix Double -> Matrix Double -> Either MathError (Matrix Double)
```

```c
hmath_status hmath_geometry_compose_transforms(hmath_context *context, const hmath_value *matrix, const hmath_value *matrix2, hmath_value **out);
```

## `cull_box`

`geometry.cull_box(frustum, aabb)`

True means the closed 3D AABB may be visible; corners need not be allocated.

```haskell
Frustum -> AABB -> Either MathError Bool
```

```c
hmath_status hmath_geometry_cull_box(hmath_context *context, const hmath_value *frustum, const hmath_value *aabb, hmath_value **out);
```

## `cull_sphere`

`geometry.cull_sphere(frustum, sphere)`

True means the closed sphere may be visible (conservative plane culling).

```haskell
Frustum -> Sphere -> Either MathError Bool
```

```c
hmath_status hmath_geometry_cull_sphere(hmath_context *context, const hmath_value *frustum, const hmath_value *sphere, hmath_value **out);
```

## `extract_frustum`

`geometry.extract_frustum(matrix)`

 Extract six inward clipping planes from projection*view. Plane normals are normalized so signed plane values are distances in world coordinates. 

```haskell
Matrix Double -> Either MathError Frustum
```

```c
hmath_status hmath_geometry_extract_frustum(hmath_context *context, const hmath_value *matrix, hmath_value **out);
```

## `inverse_transform`

`geometry.inverse_transform(matrix)`

Gauss-Jordan inverse with partial pivoting, bounded to matrices of size 17.

```haskell
Matrix Double -> Either MathError (Matrix Double)
```

```c
hmath_status hmath_geometry_inverse_transform(hmath_context *context, const hmath_value *matrix, hmath_value **out);
```

## `look_at`

`geometry.look_at(point3, point32, point33)`

World-to-camera transform from eye, target and nonparallel up direction.

```haskell
Point3 -> Point3 -> Point3 -> Either MathError (Matrix Double)
```

```c
hmath_status hmath_geometry_look_at(hmath_context *context, const hmath_value *point3, const hmath_value *point32, const hmath_value *point33, hmath_value **out);
```

## `orthographic`

`geometry.orthographic(number, number2, number3, number4, number5, number6)`

Orthographic bounds with left<right, bottom<top and 0<=near<far.

```haskell
Double -> Double -> Double -> Double -> Double -> Double -> Either MathError (Matrix Double)
```

```c
hmath_status hmath_geometry_orthographic(hmath_context *context, const hmath_value *number, const hmath_value *number2, const hmath_value *number3, const hmath_value *number4, const hmath_value *number5, const hmath_value *number6, hmath_value **out);
```

## `perspective`

`geometry.perspective(number, number2, number3, number4)`

Vertical field of view in (0,pi), positive aspect, 0<near<far.

```haskell
Double -> Double -> Double -> Double -> Either MathError (Matrix Double)
```

```c
hmath_status hmath_geometry_perspective(hmath_context *context, const hmath_value *number, const hmath_value *number2, const hmath_value *number3, const hmath_value *number4, hmath_value **out);
```

## `constrained_delaunay`

`geometry.constrained_delaunay(values, values2)`

 Insert noncrossing constrained edges by convex quadrilateral flips, then Lawson-flip every unconstrained illegal edge. Work is bounded explicitly. 

```haskell
[Point2] -> [(Int, Int)] -> Either MathError [IndexedTriangle]
```

```c
hmath_status hmath_geometry_constrained_delaunay(hmath_context *context, const hmath_value *values, const hmath_value *values2, hmath_value **out);
```

## `delaunay`

`geometry.delaunay(values)`

 Incremental cavity replacement. Cocircular insertion uses a strict in-circle predicate, giving a deterministic (not unique) valid diagonal. 

```haskell
[Point2] -> Either MathError [IndexedTriangle]
```

```c
hmath_status hmath_geometry_delaunay(hmath_context *context, const hmath_value *values, hmath_value **out);
```

## `ear_clip`

`geometry.ear_clip(polygon)`

 Ear clipping of a simple polygon. Collinear boundary vertices are removed from the active ring; returned triangles retain original indices. 

```haskell
Polygon -> Either MathError [IndexedTriangle]
```

```c
hmath_status hmath_geometry_ear_clip(hmath_context *context, const hmath_value *polygon, hmath_value **out);
```

## `voronoi`

`geometry.voronoi(rectangle, values)`

 Voronoi cells clipped to an ordered nonzero rectangle, one polygon ring per site (empty only if the site lies outside the clipping rectangle). Direct pairwise half-plane clipping is O(n^3), limited to 128 sites. Bisector classification and intersections use exact Rational arithmetic; final vertices are rounded once to Double. 

```haskell
Rectangle -> [Point2] -> Either MathError [[Point2]]
```

```c
hmath_status hmath_geometry_voronoi(hmath_context *context, const hmath_value *rectangle, const hmath_value *values, hmath_value **out);
```

