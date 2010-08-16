package de.upb.reconos.grasp.physics;


import java.io.Serializable;

import de.upb.reconos.grasp.interfaces.ForceField;
import de.upb.reconos.grasp.math.Vector2d;


public class DualHorizontalForceField implements ForceField, Serializable {

	private static final long serialVersionUID = 1L;
	public MassPoint centerPoint;
	public double strength;
	public double height;
	public double width;
	
	public DualHorizontalForceField(MassPoint centerPoint,
			double strength, double width, double height){
		this.centerPoint = centerPoint;
		this.strength = strength;
		this.width = width;
		this.height = height;
	}
	
	public void applyForceToPoint(ChargedPoint p) {
		if(p == centerPoint) return;
		
		double dy = p.position.getY() - centerPoint.position.getY();
		if(dy < -height/2){
			dy += height/2;
		}
		else if(dy > height/2){
			dy -= height/2;
		}
		else{
			dy = 0;
		}
		double dx = p.position.getX() - centerPoint.position.getX();
		if(dx < 0){
			dx = dx + width/2;
		}
		else if(dx > 0){
			dx = dx - width/2;
		}
		
		Vector2d dir = new Vector2d(dx,dy);
		double l = dir.length();
		if(l < 1) l = 1;
		
		double F = p.charge*strength*l;
		dir.setLength(F);
		
		p.addForce(-dir.getX(), -dir.getY());
		//System.err.println("HFF(" + this + "): " + dir.getX());
		//centerPoint.addForce(dir.getX(), dir.getY());
	}

	public void applyForce() {}
	public void relax() {}
	public void update(double dt) {}
}
