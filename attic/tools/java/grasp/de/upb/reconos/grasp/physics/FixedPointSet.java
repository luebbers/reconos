package de.upb.reconos.grasp.physics;


import java.io.Serializable;
import java.util.Vector;

import de.upb.reconos.grasp.interfaces.Animated;
import de.upb.reconos.grasp.math.Vector2d;


public class FixedPointSet implements Animated, Serializable  {

	private static final long serialVersionUID = 1L;
	public Vector<ChargedPoint> points;
	
	public FixedPointSet(){
		points = new Vector<ChargedPoint>();
	}
	
	public void applyForce() {}

	public void update(double dt) {
		Vector2d F = new Vector2d();
		double m = 0;
		for(int i = 0; i < points.size(); i++){
			ChargedPoint p = points.get(i);
			m += p.mass;
			F.setX(F.getX() + p.acceleration.getX()*p.mass);
			F.setY(F.getY() + p.acceleration.getY()*p.mass);
		}
		F.mul(1.0/m);
		
		ChargedPoint p0 = points.get(0);
		
		for(ChargedPoint p : points){
			p.velocity.set(p0.velocity.getX(), p0.velocity.getY());
			p.acceleration.set(F.getX(), F.getY());
			p.update(dt);
		}		
	}
	
	public void relax() {}

}
