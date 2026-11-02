# SPDX-License-Identifier: MPL-2.0
"""Compare every concrete Geometry function with independent original Haskell calls."""

import argparse
import math
import os
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

from generate_geometry_bindings import TYPES, entries, public_name, result_type
from generate_graph_bindings import split_top

ROOT = Path(__file__).resolve().parent.parent


def fp(value):
    return (
        "nan"
        if math.isnan(value)
        else str(struct.unpack("!Q", struct.pack("!d", value))[0])
    )


def hsencode(typ):
    if typ in TYPES:
        return "(show :: G." + typ + " -> String)"
    if typ == "IndexedTriangle":
        return hsencode("(Int,Int,Int)")
    if typ == "Matrix Double":
        return "matrix"
    if typ == "Ordering":
        return "(\\x -> show (case x of LT -> (-1::Int);EQ -> 0;GT -> 1))"
    if typ == "Double":
        return "fp"
    if typ in ("Int", "Bool"):
        return "show"
    if typ.startswith("Maybe (Maybe "):
        inner = typ[len("Maybe (Maybe ") : -1]
        return (
            '(\\x -> case x of Nothing -> "N0";Just Nothing -> "N1";Just (Just y) -> "N2("++'
            + hsencode(inner)
            + ' y++")")'
        )
    if typ.startswith("Maybe "):
        return (
            '(maybe "Nothing" (\\x -> "Just("++'
            + hsencode(typ[6:].strip())
            + ' x++")"))'
        )
    if typ.startswith("["):
        return "(list " + hsencode(typ[1:-1]) + ")"
    if typ.startswith("("):
        parts = split_top(typ[1:-1], ",")
        variables = ["v" + str(k) for k in range(len(parts))]
        if len(parts) == 1:
            return hsencode(parts[0])
        return (
            "(\\("
            + ",".join(variables)
            + ') -> "("++intercalate ";" ['
            + ",".join(hsencode(t) + " " + v for t, v in zip(parts, variables))
            + ']++")")'
        )
    raise AssertionError(typ)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", type=Path, required=True)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(args.library.resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath
    from _hmath_native import geometry as g
    from _hmath_native import matrix as m
    from _hmath_native._value import Value

    owners = []

    def own(x):
        owners.append(x)
        return x

    p2 = [own(g.p2(*p)) for p in [(0, 0), (2, 0), (0, 2), (0.5, 0.5), (1, -1), (1, 1)]]
    p3 = [
        own(g.p3(*p))
        for p in [
            (0, 0, 0),
            (1, 0, 0),
            (0, 1, 0),
            (0, 0, 1),
            (0.25, 0.5, 0.25),
            (0, 0, 2),
            (0, 0, -2),
            (1, 1, 1),
        ]
    ]
    nd = [
        own(g.point_nd_raw(p))
        for p in [
            [0, 0, 0],
            [1, 0, 0],
            [0, 1, 0],
            [0, 0, 1],
            [0.25, 0.5, 0.25],
            [1, 1, 1],
            [-1, -1, -1],
        ]
    ]
    bad2 = own(g.p2(math.nan, 0))
    bad3 = own(g.p3(math.nan, 0, 0))
    badnd = own(g.point_nd_raw([math.nan]))
    line = own(g.line(nd[0], nd[3]))
    parallel = own(g.line(nd[3], nd[1]))
    coincident = own(g.line(nd[0], nd[1]))
    segment = own(g.segment(nd[0], nd[5]))
    plane = own(g.plane(p3[3], 0))
    plane_x = own(g.plane(p3[1], 0))
    plane_shift = own(g.plane(p3[3], 1))
    triangle = own(g.triangle(p2[0], p2[1], p2[2]))
    triangle_b = own(g.triangle(p2[3], p2[1], p2[2]))
    rectangle = own(g.rectangle(g.p2(-1, -1), g.p2(3, 3)))
    circle = own(g.circle(p2[0], 1))
    circle_b = own(g.circle(g.p2(1, 0), 1))
    ellipse = own(g.ellipse(p2[0], 2, 1, 0.3))
    polygon = own(g.polygon(p2[:3]))
    polygon_b = own(g.polygon([p2[3], p2[1], p2[2]]))
    sphere = own(g.sphere(p3[0], 1))
    box = own(g.aabb(nd[6], nd[5]))
    obb = own(g.obb(p3[0], p3[1:4], p3[7]))
    capsule = own(g.capsule(p3[0], p3[5], 1))
    cylinder = own(g.cylinder(p3[0], p3[5], 1))
    cone = own(g.cone(p3[0], p3[5], 1))
    ray = own(g.ray(p3[6], p3[3]))
    identity = own(m.identity_checked(4))
    linear = own(m.identity_checked(3))
    wrong_matrix = own(m.from_list_checked(2, 3, [1, 0, 0, 0, 1, 0]))
    frustum = own(g.extract_frustum(identity))
    cloud = own(g.point_cloud(nd[:6]))
    index = own(g.build_spatial_index(g.kd_tree(), cloud))
    neighbor = own(g.neighbor_query([(0, 0.5), (1, 0.25)], 2, True))
    penetration = own(g.penetration(0.25, p2[3], 0.5, 2))
    kd = own(g.kd_tree())
    badkind = own(g.spatial_hash(math.nan))
    metric = own(g.euclidean())
    badmetric = own(g.minkowski(-1))
    hull = own(g.monotone_chain())
    operation = own(g.intersection())
    fixed = {
        "Line": (line, "lineA"),
        "Ray": (ray, "rayA"),
        "Segment": (segment, "segmentA"),
        "Plane": (plane, "planeA"),
        "Triangle": (triangle, "triangleA"),
        "Rectangle": (rectangle, "rectangleA"),
        "Circle": (circle, "circleA"),
        "Ellipse": (ellipse, "ellipseA"),
        "Polygon": (polygon, "polygonA"),
        "Sphere": (sphere, "sphereA"),
        "AABB": (box, "boxA"),
        "OBB": (obb, "obbA"),
        "Capsule": (capsule, "capsuleA"),
        "Cylinder": (cylinder, "cylinderA"),
        "Cone": (cone, "coneA"),
        "Frustum": (frustum, "frustumA"),
        "PointCloud": (cloud, "cloudA"),
        "SpatialIndex": (index, "indexA"),
        "NeighborQuery": (neighbor, "neighborA"),
        "Penetration": (penetration, "penetrationA"),
        "HullAlgorithm": (hull, "G.MonotoneChain"),
        "BooleanOperation": (operation, "G.Intersection"),
    }

    def encode(typ, value):
        if typ in TYPES:
            return g.describe(value)
        if typ == "IndexedTriangle":
            return encode("(Int,Int,Int)", value)
        if typ == "Matrix Double":
            return (
                str(value.shape[0])
                + ","
                + str(value.shape[1])
                + ":"
                + encode("[Double]", value.to_list())
            )
        if typ == "Double":
            return fp(value)
        if typ == "Ordering":
            return str(int(value))
        if typ in ("Int", "Bool"):
            return str(value)
        if typ.startswith("Maybe (Maybe "):
            inner = typ[len("Maybe (Maybe ") : -1]
            return (
                "N0"
                if not value[0]
                else "N1"
                if value[1] is None
                else "N2(" + encode(inner, value[1]) + ")"
            )
        if typ.startswith("Maybe "):
            return (
                "Nothing"
                if value is None
                else "Just(" + encode(typ[6:].strip(), value) + ")"
            )
        if typ.startswith("["):
            return "[" + ",".join(encode(typ[1:-1], x) for x in value) + "]"
        if typ.startswith("("):
            fields = split_top(typ[1:-1], ",")
            return (
                encode(fields[0], value)
                if len(fields) == 1
                else "(" + ";".join(encode(t, x) for t, x in zip(fields, value)) + ")"
            )
        raise AssertionError(typ)

    def fixture(entry, typ, k, bad):
        name = entry["name"]
        if typ == "Point2":
            if bad:
                return bad2, "bad2"
            if name in ("lineIntersection", "segmentIntersection"):
                j = [0, 1, 4, 5][k]
            elif name in ("triangleLocation", "polygonLocation", "ellipseContains"):
                j = 3
            else:
                j = min(k, 3)
            return p2[j], "p2" + str(j)
        if typ == "Point3":
            if bad:
                return bad3, "bad3"
            j = (
                [6, 0, 2][k]
                if name == "lookAt"
                else 4
                if name
                in (
                    "sphereSDF",
                    "capsuleSDF",
                    "cylinderSDF",
                    "coneSDF",
                    "obbSDF",
                    "pointPlaneDistance",
                    "sphereContains",
                )
                else k % 4
            )
            return p3[j], "p3" + str(j)
        if typ == "PointND":
            return (badnd, "badnd") if bad else (nd[4 + k % 2], "nd" + str(4 + k % 2))
        if typ == "SpatialKind":
            return (badkind, "G.SpatialHash (0/0)") if bad else (kd, "G.KDTree")
        if typ == "Metric":
            return (badmetric, "G.Minkowski (-1)") if bad else (metric, "G.Euclidean")
        if typ in fixed:
            if k > 0 and typ in ("Plane", "Triangle", "Polygon", "Circle"):
                return {
                    "Plane": (plane_x, "planeX"),
                    "Triangle": (triangle_b, "triangleB"),
                    "Polygon": (polygon_b, "polygonB"),
                    "Circle": (circle_b, "circleB"),
                }[typ]
            return fixed[typ]
        if typ == "Matrix Double":
            return (
                (wrong_matrix, "wrongMatrix")
                if bad
                else (linear, "linearA")
                if name == "affineTransform"
                else (identity, "identityA")
            )
        if typ == "Int":
            value = -1 if bad else (30 if name in ("gjk", "epa", "nearestQuery") else 2)
            return value, "(" + str(value) + ")"
        if typ == "Bool":
            return not bad, "False" if bad else "True"
        if typ == "Double":
            if bad:
                return math.inf, "(1/0)"
            value = (
                [-1, 1, -1, 1, 1, 10][k]
                if name == "orthographic"
                else [1, 1, 1, 10][k]
                if name == "perspective"
                else 1e-8
                if name == "epa"
                else 0.25 * (k + 1)
            )
            return value, "(" + str(value) + ")"
        if typ == "[Point2]":
            return ([], "[]") if bad else (p2[:3], "[p20,p21,p22]")
        if typ == "[Point3]":
            return ([], "[]") if bad else (p3[1:4], "[p31,p32,p33]")
        if typ == "[PointND]":
            return ([], "[]") if bad else (nd[:6], "[nd0,nd1,nd2,nd3,nd4,nd5]")
        if typ == "[Plane]":
            planes = [] if bad else [plane] * 6
            return planes, "[]" if bad else "replicate 6 planeA"
        if typ == "[Double]":
            return (
                ([math.nan], "[0/0]") if bad else ([0.25, 0.5, 0.75], "[0.25,0.5,0.75]")
            )
        if typ == "[[Double]]":
            return (
                ([], "[]")
                if bad
                else ([[1, 0, 0], [0, 1, 0], [0, 0, 1]], "[[1,0,0],[0,1,0],[0,0,1]]")
            )
        if typ == "[(Int, Int)]":
            return ([(-1, 1)], "[(-1,1)]") if bad else ([(0, 1)], "[(0,1)]")
        if typ == "[(Int, Double)]":
            return ([(0, 0.5), (1, 0.25)], "[(0,0.5),(1,0.25)]")
        if typ == "(Point3, Point3, Point3)":
            return ((p3[0], p3[1], p3[2]), "(p30,p31,p32)")
        raise AssertionError((name, typ))

    lines = [
        "import qualified HMath.Geometry as G",
        "import qualified HMath.Matrix as M",
        "import HMath.Error (MathError)",
        "import Data.List (intercalate)",
        "import GHC.Float",
        'fp x=if isNaN x then "nan" else show (castDoubleToWord64 x)',
        'list e xs="["++intercalate "," (map e xs)++"]"',
        'matrix x=let (a,b)=M.shape x in show a++","++show b++":"++list fp (M.toList x)',
        "right (Right x)=x",
        "right (Left e)=error (show e)",
        "emit :: (a->String)->Either MathError a->IO ()",
        'emit e (Right x)=putStrLn ("OK:"++e x)',
        'emit _ (Left e)=putStrLn ("ERR:"++show e)',
    ]
    for j, (a, b) in enumerate([(0, 0), (2, 0), (0, 2), (0.5, 0.5), (1, -1), (1, 1)]):
        lines.append("p2" + str(j) + "=G.P2 (" + str(a) + ") (" + str(b) + ")")
    for j, values in enumerate(
        [
            (0, 0, 0),
            (1, 0, 0),
            (0, 1, 0),
            (0, 0, 1),
            (0.25, 0.5, 0.25),
            (0, 0, 2),
            (0, 0, -2),
            (1, 1, 1),
        ]
    ):
        lines.append(
            "p3" + str(j) + "=G.P3 " + " ".join("(" + str(x) + ")" for x in values)
        )
    for j, values in enumerate(
        [
            [0, 0, 0],
            [1, 0, 0],
            [0, 1, 0],
            [0, 0, 1],
            [0.25, 0.5, 0.25],
            [1, 1, 1],
            [-1, -1, -1],
        ]
    ):
        lines.append("nd" + str(j) + "=G.PointND " + str(values))
    lines += [
        "bad2=G.P2 (0/0) 0",
        "bad3=G.P3 (0/0) 0 0",
        "badnd=G.PointND [0/0]",
        "lineA=G.Line nd0 nd3",
        "parallel=G.Line nd3 nd1",
        "coincident=G.Line nd0 nd1",
        "segmentA=G.Segment nd0 nd5",
        "planeA=G.Plane p33 0",
        "planeX=G.Plane p31 0",
        "planeShift=G.Plane p33 1",
        "triangleA=G.Triangle p20 p21 p22",
        "triangleB=G.Triangle p23 p21 p22",
        "rectangleA=G.Rectangle (G.P2 (-1) (-1)) (G.P2 3 3)",
        "circleA=G.Circle p20 1",
        "circleB=G.Circle (G.P2 1 0) 1",
        "ellipseA=G.Ellipse p20 2 1 0.3",
        "polygonA=G.Polygon [p20,p21,p22]",
        "polygonB=G.Polygon [p23,p21,p22]",
        "sphereA=G.Sphere p30 1",
        "boxA=G.AABB nd6 nd5",
        "obbA=G.OBB p30 [p31,p32,p33] p37",
        "capsuleA=G.Capsule p30 p35 1",
        "cylinderA=G.Cylinder p30 p35 1",
        "coneA=G.Cone p30 p35 1",
        "rayA=G.Ray p36 p33",
        "identityA=right (M.identityChecked 4::Either MathError (M.Matrix Double))",
        "linearA=right (M.identityChecked 3::Either MathError (M.Matrix Double))",
        "wrongMatrix=right (M.fromListChecked 2 3 [1,0,0,0,1,0::Double])",
        "frustumA=right (G.extractFrustum identityA)",
        "cloudA=right (G.pointCloud [nd0,nd1,nd2,nd3,nd4,nd5])",
        "indexA=right (G.buildSpatialIndex G.KDTree cloudA)",
        "neighborA=G.NeighborQuery [(0,0.5),(1,0.25)] 2 True",
        "penetrationA=G.Penetration 0.25 p23 0.5 2",
        "main=do",
    ]
    cases = []
    for entry in entries():
        argtypes = split_top(entry["signature"], "->")[:-1]
        result, checked = result_type(entry["signature"])
        for bad in (False, True):
            values = [fixture(entry, t, k, bad) for k, t in enumerate(argtypes)]
            call = "G." + entry["name"] + "".join(" (" + hs + ")" for _, hs in values)
            if not checked:
                call = "Right (" + call + ")"
            lines.append("  emit " + hsencode(result) + " (" + call + ")")
            cases.append((entry, result, [x for x, _ in values], bad))
    extras = [
        (
            "line-parallel",
            "G.linePlaneIntersection parallel planeA",
            "Maybe (Maybe Point3)",
            lambda: g.line_plane_intersection(parallel, plane),
        ),
        (
            "line-coincident",
            "G.linePlaneIntersection coincident planeA",
            "Maybe (Maybe Point3)",
            lambda: g.line_plane_intersection(coincident, plane),
        ),
        (
            "plane-parallel",
            "G.planeIntersection planeA planeShift",
            "Maybe (Maybe Line)",
            lambda: g.plane_intersection(plane, plane_shift),
        ),
        (
            "plane-coincident",
            "G.planeIntersection planeA planeA",
            "Maybe (Maybe Line)",
            lambda: g.plane_intersection(plane, plane),
        ),
    ]
    for _, call, result, _ in extras:
        lines.append("  emit " + hsencode(result) + " (" + call + ")")
    with tempfile.TemporaryDirectory(prefix="hmath-geometry-oracle-") as directory:
        path = Path(directory)
        source = path / "Main.hs"
        source.write_text("\n".join(lines) + "\n")
        subprocess.run(
            [
                "ghc",
                "-O0",
                "-isrc",
                "-outputdir",
                directory,
                "-stubdir",
                directory,
                str(source),
                "-o",
                str(path / "oracle"),
            ],
            cwd=ROOT,
            check=True,
            stdout=subprocess.DEVNULL,
        )
        expected = subprocess.check_output(
            [str(path / "oracle")], text=True
        ).splitlines()

    def close(value):
        if isinstance(value, Value) or hasattr(value, "close"):
            value.close()
        elif isinstance(value, (tuple, list)):
            for child in value:
                close(child)

    for k, (entry, result, values, bad) in enumerate(cases):
        value = None
        try:
            value = getattr(g, public_name(entry))(*values)
            actual = "OK:" + encode(result, value)
        except hmath.HMathError as error:
            assert error.math_error is not None, (entry["name"], error)
            actual = "ERR:" + str(error.math_error)
        finally:
            close(value)
        assert actual == expected[k], (entry["name"], bad, actual, expected[k])
    for k, (label, _, result, function) in enumerate(extras, len(cases)):
        value = function()
        try:
            assert "OK:" + encode(result, value) == expected[k], (
                label,
                value,
                expected[k],
            )
        finally:
            close(value)
    assert g.line_plane_intersection(parallel, plane) == (False, None)
    assert g.line_plane_intersection(coincident, plane) == (True, None)
    parent = g.circle(p2[0], -1)
    label, fields = parent.parts
    parent.close()
    assert label == "Circle" and fields[1] == -1 and fields[0].coordinates == [0, 0]
    fields[0].close()
    assert p2[0] == g.p2(0, 0)
    assert p2[0] != p2[1]
    with bad2.clone().decode() as duplicate:
        assert bad2 != duplicate  # original Double NaN Eq remains non-reflexive
    for owner in owners:
        owner.close()
    print(
        f"Geometry: {len(expected)} direct Haskell cases, original structured errors, all nested Maybe states, constructor fields and ownership passed."
    )


if __name__ == "__main__":
    main()
