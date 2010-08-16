package de.upb.reconos.grasp.physics;


import java.io.Serializable;

import de.upb.reconos.grasp.interfaces.Rectangle;
import de.upb.reconos.grasp.math.Vector2d;


public class RectangleSpring extends Spring implements Serializable {

	private static final long serialVersionUID = 1L;
	private Rectangle rectangle;
	
	public RectangleSpring(Rectangle rect, ChargedPoint a, ChargedPoint b){
		super(a,b);
		rectangle = rect;
	}
	
	public RectangleSpring(Rectangle rect, ChargedPoint a,
			ChargedPoint b, double springConstant)
	{
		super(a,b,springConstant);
		rectangle = rect;
		relaxedLength = 1;
	}
	
	public void applyForce() {
		Vector2d dir = Vector2d.sub(pointA.position, pointB.position);
		double dx = Math.abs(dir.getX());
		double dy = Math.abs(dir.getY());
		double l = Math.max(2*dx/rectangle.getWidth(), 2*dy/rectangle.getHeight());
		double dl = l - relaxedLength;
		double F = dl*springConstant;
		
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
		
		dir.setLength(F);
		pointA.addForce(-dir.getX(), -dir.getY());
		pointB.addForce(dir.getX(), dir.getY());
	}
}
