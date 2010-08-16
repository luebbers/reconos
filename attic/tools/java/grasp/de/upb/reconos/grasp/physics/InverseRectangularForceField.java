package de.upb.reconos.grasp.physics;


import java.io.Serializable;
import java.util.HashSet;
import java.util.Set;

import de.upb.reconos.grasp.interfaces.ForceField;
import de.upb.reconos.grasp.math.CenterPointRectangle;


public class InverseRectangularForceField implements ForceField, Serializable {

	private static final long serialVersionUID = 1L;
	private CenterPointRectangle rectangle;
	private double rate;
	double minWidth;
	double minHeight;
	private MassPoint leftPoint;
	private MassPoint rightPoint;
	private MassPoint topPoint;
	private MassPoint bottomPoint;
	public Set<ChargedPoint> exclude;

	public InverseRectangularForceField(
			CenterPointRectangle rect, MassPoint point, double rate)
	{
		rectangle   = rect;
		rectangle.setCenter(point.position);
		this.rate   = rate;
		
		minWidth = rect.getWidth();
		minHeight = rect.getHeight();
		
		leftPoint   = new MassPoint(rect.getLeft(),rect.getCenter().getY());
		rightPoint  = new MassPoint(rect.getRight(),rect.getCenter().getY());
		topPoint    = new MassPoint(rect.getCenter().getX(),rect.getTop());
		bottomPoint = new MassPoint(rect.getCenter().getX(),rect.getBottom());
		
		leftPoint.mass = point.mass/4;
		rightPoint.mass = point.mass/4;
		topPoint.mass = point.mass/4;
		bottomPoint.mass = point.mass/4;
		
		exclude = new HashSet<ChargedPoint>();
	}
	
	public void setCenter(double x, double y){
		leftPoint.position.set(x - rectangle.getWidth()/2, y);
		rightPoint.position.set(x + rectangle.getWidth()/2, y);
		topPoint.position.set(x, y - rectangle.getHeight()/2);
		bottomPoint.position.set(x, y + rectangle.getHeight()/2);
		rectangle.getCenter().set(x,y);
	}
	
	public void applyForce(){
		double dw = rectangle.getWidth() - minWidth;
		double dh = rectangle.getHeight() - minHeight;
		
		double fx = 10*dw;
		double fy = 10*dh;
		
		leftPoint.addForce(fx, 0);
		rightPoint.addForce(-fx, 0);
		topPoint.addForce(0,fy);
		bottomPoint.addForce(0,-fy);
	}


	public void update(double dt) {
		leftPoint.update(dt);
		rightPoint.update(dt);
		topPoint.update(dt);
		bottomPoint.update(dt);
		rectangle.setWidth(rightPoint.position.getX()
				- leftPoint.position.getX());
		rectangle.setHeight(bottomPoint.position.getY()
				- topPoint.position.getY());
		
		rectangle.getCenter().set(0,0);
		rectangle.getCenter().add(leftPoint.position);
		rectangle.getCenter().add(rightPoint.position);
		rectangle.getCenter().add(topPoint.position);
		rectangle.getCenter().add(bottomPoint.position);
		rectangle.getCenter().mul(0.25);
	}
	
	public void applyForceToPoint(ChargedPoint p) {
		if(exclude.contains(p)) return;
		
		double fx = 0;
		double fy = 0;
		
		if(p.position.getX() < rectangle.getLeft()){
			fx = (rectangle.getLeft() - p.position.getX())*p.charge*rate;
			leftPoint.addForce(-fx, 0);
		}
		else if(p.position.getX() > rectangle.getRight()){
			fx = (rectangle.getRight() - p.position.getX())*p.charge*rate;
			rightPoint.addForce(-fx, 0);
		}
		if(p.position.getY() < rectangle.getTop()){
			fy = (rectangle.getTop() - p.position.getY())*p.charge*rate;
			topPoint.addForce(0, -fy);
		}
		else if(p.position.getY() > rectangle.getBottom()){
			fy = (rectangle.getBottom() - p.position.getY())*p.charge*rate;
			bottomPoint.addForce(0, -fy);
		}
		
		p.addForce(fx, fy);
	}

	public void relax() {}

	public MassPoint getBottomPoint() {
		return bottomPoint;
	}

	public MassPoint getLeftPoint() {
		return leftPoint;
	}

	public MassPoint getRightPoint() {
		return rightPoint;
	}

	public MassPoint getTopPoint() {
		return topPoint;
	}
}
