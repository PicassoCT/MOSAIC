//Gets Light Reflections
vec4 RaymarchRainReflectionRinglets(vec3 raySourcePixel, vec3 rayDirection)
{
	vec4 reflectedRayMarchedColor = vec4(0.0,0.0, 0.0, 1.0);
	//Get Intersection - check for upright of surface vector 
	
	//if upright get Reflection Base Value
	//{		
		//Check for RaindropImpact
			//if Randrop imapct Get Raindrop surface ringlet
	
		//computate the directional mirror vector
			
			//Check visibility relative to reflection surface
			
		//Add Reflection mirror Value
	
	}	
	return reflectedRayMarchedColor;
}

int RAY_MARCH_MAX_DISTANCE_100M = 20; 
vec4 RaymarchReflection(vec3 sourcePixel, vec3 rayDirection)
{
	for (int i= 0; i < RAY_MARCH_MAX_DISTANCE; i++) 
	{
		vec3 pixelPos = mix( sourcePixel, sourcePixel * rayDirection * (float)(RAY_MARCH_MAX_DISTANCE  (i/RAY_MARCH_MAX_DISTANCE)));
		//if pixelPos has depthmask Surface in Reach (reflect that color * logreduced by distance)
		vec2 uvPixelCoord = GetUVFromWorld( pixelPos);
		float distance = distance(sourcePixel, pixelPos); 
		return sampler2D(screentex, uvPixelCoord) * 1/sqrt(distance);
	}
	return vec4 (0.0, 0.0, 0.0, 1.0);
}