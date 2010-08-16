package de.upb.reconos.grasp.physics;


import java.io.Serializable;

import de.upb.reconos.grasp.interfaces.Animated;


public class ChargedPoint extends MassPoint implements Animated, Serializable {

	private static final long serialVersionUID = 1L;
	public double charge;
	
	public ChargedPoint(double x, double y){
		super(x,y);
		charge = 1;
	}
	
	public void applyForce(){}
}
