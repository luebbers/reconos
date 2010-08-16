package de.upb.reconos.grasp.physics;


import java.io.Serializable;
import java.util.Vector;

import de.upb.reconos.grasp.interfaces.Animated;
import de.upb.reconos.grasp.interfaces.ForceField;
import de.upb.reconos.grasp.math.Vector2d;


public class ChargeDomain implements Animated, Serializable {

	private static final long serialVersionUID = 1L;
	private Vector<ChargedPoint> points;
	private Vector<ForceField> forceFields;
	
	private double falloff;
	
	public ChargeDomain(){
		points = new Vector<ChargedPoint>();
		forceFields = new Vector<ForceField>();
		falloff = 600;
	}
	
	public void applyForce() {
		for(ForceField f : forceFields){
			f.applyForce();
		}
		
		for(ForceField f : forceFields){
			for(ChargedPoint p : points){
				f.applyForceToPoint(p);
			}
		}
		
		for(int i = 0; i < points.size(); i++){
			ChargedPoint a = points.get(i);
			
			for(int j = i + 1; j < points.size(); j++){
				ChargedPoint b = points.get(j);
				Vector2d dir = Vector2d.sub(a.position, b.position);
				double l = dir.length();
				if(l > falloff) continue;
				if(l < 1) l = 1;
				if(l != l) l = 1;
				
				double F = 6000*a.charge*b.charge*(falloff - l)/(l*l);
				if(F != F){
					System.err.println("l = " + l);
					System.err.println("b = " + b.position.getX() + "," + b.position.getY());
					System.err.println("dir = " + dir.getX() + "," + dir.getY());
					throw new RuntimeException();
				}
				dir.setLength(F);
				a.addForce(dir.getX(), dir.getY());
				b.addForce(-dir.getX(), -dir.getY());
			}
		}
	}

	public void update(double dt) {
		for(ForceField f : forceFields){
			f.update(dt);
		}
	}
	
	public void relax(){}
	
	public void add(ChargedPoint p){
		points.add(p);
	}
	
	public void remove(ChargedPoint p){
		while(points.remove(p));
	}
	
	public void add(ForceField f){
		forceFields.add(f);
	}
	
	public void remove(ForceField f){
		while(forceFields.remove(f));
	}
}
