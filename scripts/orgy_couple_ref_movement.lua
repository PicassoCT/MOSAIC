return {
["REF_MOVEMENT"]={
		{
			['time'] = 1,
			['commands'] = 
			{
				{c ='turn',p="p1_l_body", a=z_axis, t=1.570796, s=1.624962},					
				{c='turn',p="p1_left_u_arm", a=y_axis, t=-1.570796, s=1.624962},
				{c='turn',p="p1_right_u_arm", a=y_axis, t=-0.785398, s=0.812481},
				{c='turn',p="p2_l_body", a=z_axis, t=-1.570796, s=1.624962},
				{c='turn',p="p2_left_u_arm", a=z_axis, t=-0.785398, s=0.812481},
				{c='turn',p="p2_right_u_arm", a=z_axis, t=0.785398, s=0.812481},
			}
		},
		{
			['time'] = 30,
			['commands'] = {
			}
		},
	}
}
