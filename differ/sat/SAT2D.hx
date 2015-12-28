package differ.sat;

import differ.math.*;
import differ.shapes.*;
import differ.data.*;
import differ.math.Util.*;
import differ.sat.Common;

/** Implementation details for the 2D SAT collision queries.
    Used by the various shapes, and Collision API, mostly internally.  */
class SAT2D {

        /** Internal api - test a circle against a polygon */
    public static function testCircleVsPolygon( circle:Circle, polygon:Polygon, flip:Bool=false ) : ShapeCollision {

        var into = new ShapeCollision();
        var verts = polygon.transformedVertices;

        var circleX = circle.x;
        var circleY = circle.y;

        var testDistance : Float = 0x3FFFFFFF;
        var distance = 0.0, closestX = 0.0, closestY = 0.0;
        for(i in 0 ... verts.length) {

            distance = vec_lengthsq(circleX - verts[i].x, circleY - verts[i].y);

            if(distance < testDistance) {
                testDistance = distance;
                closestX = verts[i].x;
                closestY = verts[i].y;
            }

        } //for

        var normalAxisX = closestX - circleX;
        var normalAxisY = closestY - circleY;
        var normAxisLen = vec_length(normalAxisX, normalAxisY);
            normalAxisX = vec_normalize(normAxisLen, normalAxisX);
            normalAxisY = vec_normalize(normAxisLen, normalAxisY);


            //project all its points, 0 outside the loop
        var test = 0.0;
        var min1 = vec_dot(normalAxisX, normalAxisY, verts[0].x, verts[0].y);
        var max1 = min1;

        for(j in 1 ... verts.length) {
            test = vec_dot(normalAxisX, normalAxisY, verts[j].x, verts[j].y);
            if(test < min1) min1 = test;
            if(test > max1) max1 = test;
        } //each vert

            // project the circle
        var max2 = circle.transformedRadius;
        var min2 = -circle.transformedRadius;
        var offset = vec_dot(normalAxisX, normalAxisY, -circleX, -circleY);
            
        min1 += offset;
        max1 += offset;

        var test1 = min1 - max2;
        var test2 = min2 - max1;

            //if either test is greater than 0, there is a gap, we can give up now.
        if(test1 > 0 || test2 > 0) return null;

            // circle distance check
        var distMin = -(max2 - min1);
        if(flip) distMin *= -1;

        into.overlap = distMin;
        into.unitVectorX = normalAxisX;
        into.unitVectorY = normalAxisY;
        var closest = Math.abs(distMin);

            // find the normal axis for each point and project
        for(i in 0 ... verts.length) {

            normalAxisX = Common.findNormalAxisX(verts, i);
            normalAxisY = Common.findNormalAxisY(verts, i);
            var aLen = vec_length(normalAxisX, normalAxisY);
            normalAxisX = vec_normalize(aLen, normalAxisX);
            normalAxisY = vec_normalize(aLen, normalAxisY);

                // project the polygon(again? yes, circles vs. polygon require more testing...)
            min1 = vec_dot(normalAxisX, normalAxisY, verts[0].x, verts[0].y);
            max1 = min1; //set max and min

            //project all the other points(see, cirlces v. polygons use lots of this...)
            for(j in 1 ... verts.length) {
                test = vec_dot(normalAxisX, normalAxisY, verts[j].x, verts[j].y);
                if(test < min1) min1 = test;
                if(test > max1) max1 = test;
            }

            // project the circle(again)
            max2 = circle.transformedRadius; //max is radius
            min2 = -circle.transformedRadius; //min is negative radius

            //offset points
            offset = vec_dot(normalAxisX, normalAxisY, -circleX, -circleY);
            min1 += offset;
            max1 += offset;

            // do the test, again
            test1 = min1 - max2;
            test2 = min2 - max1;

                //failed.. quit now
            if(test1 > 0 || test2 > 0) {
                return null;
            }

            distMin = -(max2 - min1);
            if(flip) distMin *= -1;

            if(Math.abs(distMin) < closest) {
                into.unitVectorX = normalAxisX;
                into.unitVectorY = normalAxisY;
                into.overlap = distMin;
                closest = Math.abs(distMin);
            }

        } //for

        //if you made it here, there is a collision!!!!!

        into.shape1 = if(flip) polygon else circle;
        into.shape2 = if(flip) circle else polygon;
        into.separationX = into.unitVectorX * into.overlap;
        into.separationY = into.unitVectorY * into.overlap;

        if(!flip) {
            into.unitVectorX = -into.unitVectorX;
            into.unitVectorY = -into.unitVectorY;
        }

        return into;

    } //testCircleVsPolygon

        /** Internal api - test a circle against a circle */
    public static function testCircleVsCircle( circleA:Circle, circleB:Circle, flip:Bool = false ) : ShapeCollision {
        //

        var circle1 = flip ? circleB : circleA;
        var circle2 = flip ? circleA : circleB;

            //add both radii together to get the colliding distance
        var totalRadius = circle1.transformedRadius + circle2.transformedRadius;
            //find the distance between the two circles using Pythagorean theorem. No square roots for optimization
        var distancesq = (circle1.x - circle2.x) * (circle1.x - circle2.x) + (circle1.y - circle2.y) * (circle1.y - circle2.y);

            //if your distance is less than the totalRadius square(because distance is squared)
        if(distancesq < totalRadius * totalRadius) {

            var into = new ShapeCollision();
                //find the difference. Square roots are needed here.
            var difference : Float = totalRadius - Math.sqrt(distancesq);

                into.shape1 = circle1;
                into.shape2 = circle2;

                var unitVecX = circle1.x - circle2.x;
                var unitVecY = circle1.y - circle2.y;
                var unitVecLen = vec_length(unitVecX, unitVecY);

                unitVecX = vec_normalize(unitVecLen, unitVecX);
                unitVecY = vec_normalize(unitVecLen, unitVecY);

                into.unitVectorX = unitVecX;
                into.unitVectorY = unitVecY;

                    //find the movement needed to separate the circles
                into.separationX = into.unitVectorX * difference;
                into.separationY = into.unitVectorY * difference;
                    //the magnitude of the overlap
                into.overlap = vec_length(into.separationX, into.separationY);

            return into;

        } //if distanceSq

        return null;

    } //testCircleVsCircle

        /** Internal api - test a polygon against another polygon */
    public static function testPolygonVsPolygon( polygon1:Polygon, polygon2:Polygon, flip:Bool=false ) : ShapeCollision {

        var result1 = checkPolygons(polygon1, polygon2, flip);

        if(result1 == null) return null;

        var result2 = checkPolygons(polygon2, polygon1, !flip);

        if (result2 == null) return null;

            //:todo: expose both: take the closest overlap 
        (Math.abs(result1.overlap) < Math.abs(result2.overlap)) ?
            return result1:
            return result2;

    } //testPolygonVsPolygon

        /** Internal api - test a ray against a circle */
    public static function testRayVsCircle( ray:Ray, circle:Circle ) : RayCollision {

        var delta = ray.end.clone().subtract(ray.start);
        var ray2circle = ray.start.clone().subtract(circle.position);

        var a = delta.lengthsq;
        var b = 2 * delta.dot(ray2circle);
        var c = ray2circle.dot(ray2circle) - circle.radius * circle.radius;

        var d:Float = b * b - 4 * a * c;

        if (d >= 0) {

            d = Math.sqrt(d);

            var t1:Float = (-b - d) / (2 * a);
            var t2:Float = (-b + d) / (2 * a);

            if (ray.infinite || ((t1 <= 1.0)&&(t1 >=0.0)) ) {
                return new RayCollision(circle, ray, t1, t2);
            }

        } //d>=0

        return null;

    } //testRayVsCircle

        /** Internal api - test a ray against a polygon */
    public static function testRayVsPolygon( ray:Ray, polygon:Polygon ) : RayCollision {

        var delta = ray.end.clone().subtract(ray.start);
        var vertices = polygon.transformedVertices;

        var min_u:Float = Math.POSITIVE_INFINITY;
        var max_u:Float = 0.0;

        if (vertices.length > 2) {

            var v1 = vertices[vertices.length - 1];
            var v2 = vertices[0];

            var r = intersectRayRay(ray.start, delta, v1, v2.clone().subtract(v1));

            if (r != null && r.ub >= 0.0 && r.ub <= 1.0) {
                if (r.ua < min_u) min_u = r.ua;
                if (r.ua > max_u) max_u = r.ua;
            }

            for (i in 1...vertices.length) {

                v1 = vertices[i - 1];
                v2 = vertices[i];

                r = intersectRayRay(ray.start, delta, v1, v2.clone().subtract(v1));

                if (r != null && r.ub >= 0.0 && r.ub <= 1.0) {
                    if (r.ua < min_u) min_u = r.ua;
                    if (r.ua > max_u) max_u = r.ua;
                }

            } //each vert

            if(ray.infinite || ((min_u <= 1.0) && (min_u >= 0.0)) ) {
                return new RayCollision(polygon, ray, min_u, max_u);
            }

        } //vert length > 2

        return null;

    } //testRayVsPolygon

        /** Internal api - test a ray against another ray */
    public static function testRayVsRay( ray1:Ray, ray2:Ray ) : RayIntersection {

        var delta1 = ray1.end.clone().subtract(ray1.start);
        var delta2 = ray2.end.clone().subtract(ray2.start);

        var dx = ray1.start.clone().subtract(ray2.start);

        var d = delta2.y * delta1.x - delta2.x * delta1.y;

        if (d == 0.0) return null;

        var u1 = (delta2.x * dx.y - delta2.y * dx.x) / d;
        var u2 = (delta1.x * dx.y - delta1.y * dx.x) / d;

        if ((ray1.infinite || u1 <= 1.0) && (ray2.infinite || u2 <= 1.0)) return new RayIntersection(ray1, u1, ray2, u2);

        return null;

    } //testRayVsRay

//Helpers

        /** Internal api - generate a bresenham line between given start and end points */
    public static function bresenhamLine( start:Vector, end:Vector ) : Array<Vector> {
        //

            //the array of all the points on the line
        var points:Array<Vector> = [];
        var steep:Bool = Math.abs(end.y - start.y) > Math.abs(end.x - start.x);
            //check if rise is greater than run
        var swapped:Bool = false;

            //reflect the line
        if(steep) {
            start = swap(start);
            end = swap(end);
        } //if steep

             //make sure the line goes downward
        if(start.x > end.x) {

            var t:Float = start.x;

            start.x = end.x;
            end.x = t;
            t = start.y;
            start.y = end.y;
            end.y = t;
            swapped = true;

        } //if start.x > end.x

            //x slope
        var deltax:Float = end.x - start.x;
            //y slope, positive because the lines always go  down
        var deltay:Float = Math.abs(end.y - start.y);
            //error is used instead of tracking the y values.
        var error:Float = deltax / 2;
        var ystep:Float;
        var y:Float = start.y;

        if(start.y < end.y) {
            ystep = 1;
        } else {
            ystep = -1;
        }

        var x:Int = Std.int(start.x);
        for(x in Std.int(start.x) ... Std.int(end.x)) { //for each point

            if(steep) {
                points.push(new Vector(y, x)); //if its steep, push flipped version
            } else {
                points.push(new Vector(x, y)); //push normal
            }

            error -= deltay; //change the error

            if(error < 0) {
                y += ystep; //if the error is too much, adjust the ystep
                error += deltax;
            }
        }

        if(swapped) {
            points.reverse();
        }

        return points;

    } //bresenhamLine

//Internal helpers

        /** Internal api - implementation details for testPolygonVsPolygon */
    static function checkPolygons( polygon1:Polygon, polygon2:Polygon, flip:Bool=false ) : ShapeCollision {

        var ep : Float = 0.0000000001;
        var test1 : Float; // numbers to use to test for overlap
        var test2 : Float;
        var testNum : Float; // number to test if its the new max/min
        var min1 : Float; //current smallest(shape 1)
        var max1 : Float; //current largest(shape 1)
        var min2 : Float; //current smallest(shape 2)
        var max2 : Float; //current largest(shape 2)
        var axis:Vector; //the normal axis for projection
        var offset : Float;
        var vectors1:Array<Vector>; //the points
        var vectors2:Array<Vector>; //the points
        var shortestDistance : Float = 0x3FFFFFFF;
        var into = new ShapeCollision();

        vectors1 = polygon1.transformedVertices.copy();
        vectors2 = polygon2.transformedVertices.copy();

            // add a little padding to make the test work correctly for lines
        if(vectors1.length == 2) {
            var temp = new Vector(-(vectors1[1].y - vectors1[0].y), vectors1[1].x - vectors1[0].x);
            temp.truncate(ep);
            vectors1.push(vectors1[1].add(temp));
        }

        if(vectors2.length == 2) {
            var temp = new Vector(-(vectors2[1].y - vectors2[0].y), vectors2[1].x - vectors2[0].x);
            temp.truncate(ep);
            vectors2.push(vectors2[1].add(temp));
        }

            // loop to begin projection
        for(i in 0 ... vectors1.length) {

                // get the normal axis, and begin projection
            axis = Common.findNormalAxis(vectors1, i);

                // project polygon1
            min1 = axis.dot(vectors1[0]);
            max1 = min1; //set max and min equal

            for(j in 1 ... vectors1.length) {
                testNum = axis.dot(vectors1[j]); //project each point
                if(testNum < min1) {
                    min1 = testNum;
                } //test for new smallest
                if(testNum > max1) {
                    max1 = testNum;
                } //test for new largest
            }

            // project polygon2
            min2 = axis.dot(vectors2[0]);
            max2 = min2; //set 2's max and min

            for(j in 1 ... vectors2.length) {
                testNum = axis.dot(vectors2[j]); //project the point
                if(testNum < min2) {
                    min2 = testNum;
                } //test for new min
                if(testNum > max2) {
                    max2 = testNum;
                } //test for new max
            }

            // and test if they are touching
            test1 = min1 - max2; //test min1 and max2
            test2 = min2 - max1; //test min2 and max1
            if(test1 > 0 || test2 > 0) { //if they are greater than 0, there is a gap
                return null; //just quit
            }

            var distMin : Float = -(max2 - min1);
            if(flip) distMin *= -1;
            if(Math.abs(distMin) < shortestDistance) {
                into.unitVectorX = axis.x;
                into.unitVectorY = axis.y;
                into.overlap = distMin;
                shortestDistance = Math.abs(distMin);
            }
        }

        //if you're here, there is a collision

        into.shape1 = if(flip) polygon2 else polygon1;
        into.shape2 = if(flip) polygon1 else polygon2;
        into.separationX = -into.unitVectorX * into.overlap;
        into.separationY = -into.unitVectorY * into.overlap;

        if(flip) {
            into.unitVectorX = -into.unitVectorX;
            into.unitVectorY = -into.unitVectorY;
        }

        return into;

    } //checkPolygons

        /** Internal api - swap x and y of a vector, returning a new vector. :todo: this is silly */
    static inline function swap(v:Vector) : Vector return new Vector(v.y, v.x);

        /** Internal api - same thing as rayRay, except without using Ray objects - saves the construction of a Ray object when testing Polygon/Ray. */
    static function intersectRayRay(a:Vector, adelta:Vector, b:Vector, bdelta:Vector) : { ua:Float, ub:Float } {

        var dx = a.clone().subtract(b);

        var d = bdelta.y * adelta.x - bdelta.x * adelta.y;

        if (d == 0.0) return null;

        var ua = (bdelta.x * dx.y - bdelta.y * dx.x) / d;
        var ub = (adelta.x * dx.y - adelta.y * dx.x) / d;

        return { ua : ua, ub : ub };

    } //intersectRayRay

} //SAT2D