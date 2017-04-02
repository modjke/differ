package differ.math;

@:publicFields
class Util {

    inline static function vec_lengthsq(x:Float, y:Float) : Float {
        return x * x + y * y;
    }

    inline static function vec_length(x:Float, y:Float) : Float {
        return Math.sqrt(vec_lengthsq(x,y));
    }

    inline static function vec_normalize(length:Float, component:Float) : Float {
        if(length == 0) return 0;
        return component /= length;
    }

    inline static function vec_dot(x:Float, y:Float, otherx:Float, othery:Float) : Float {
        return x * otherx + y * othery;
    }
	
	inline static function vec_distance(a:Vector, b:Vector):Float {
		return Math.sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));
	}
}