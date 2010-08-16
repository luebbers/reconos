package de.upb.reconos.grasp.physics;


import java.io.Serializable;

import de.upb.reconos.grasp.interfaces.Animated;
import de.upb.reconos.grasp.math.Vector2d;


public class Spring implements Animated, Serializable {

	private static final long serialVersionUID = 1L;
	public MassPoint pointA, pointB;
	public double relaxedLength;
	public double springConstant;
	
	public Spring(MassPoint a, MassPoint b){
		pointA = a;
		pointB = b;
		relaxedLength = Vector2d.distance(a.position, b.position);
		springConstant = 1;
	}
	
	public Spring(MassPoint a, MassPoint b, double springConstant){
		pointA = a;
		pointB = b;
		relaxedLength = Vector2d.distance(a.position, b.position);
		this.springConstant = springConstant;
	}
	
	public void dissolve(){
		pointA = pointB = null;
	}
	
	public void applyForce(){
		Vector2d dir = Vector2d.sub(pointA.position, pointB.position);
		double l = dir.length();
		double dl = l - relaxedLength;
		double F = dl*springConstant;
		dir.setLength(F);
		if(F != F){
			System.err.println("l = " + l);
			System.err.println("dl = " + dl);
			System.err.println("relaxedLength = " + relaxedLength);
			System.err.println("springConstant = " + springConstant);
			System.err.println("A = " + pointA.position.getX() + "," + pointA.position.getY());
			System.err.println("B = " + pointB.position.getX() + "," + pointB.position.getY());
			System.err.println("dir = " + dir.getX() + "," + dir.getY());
			throw new RuntimeException();
		}
		pointA.addForce(-dir.getX(), -dir.getY());
		pointB.addForce(dir.getX(), dir.getY());
	}
	
	public void update(double dt) {}
}
