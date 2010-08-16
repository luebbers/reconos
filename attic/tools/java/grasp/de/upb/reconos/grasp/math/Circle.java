package de.upb.reconos.grasp.math;

import java.io.Serializable;

public class Circle implements Serializable {

	private static final long serialVersionUID = 1L;
	public Vector2d center;
	public double radius;
	public Circle(double x, double y, double r){
		center = new Vector2d(x,y);
		radius = r;
	}
	public boolean contains(double x, double y){
		double dx = x - center.getX();
		double dy = y - center.getY();
		return Math.sqrt(dx*dx + dy*dy) <= radius;
	}
	
	public Vector2d closestPoint(Vector2d v){
		Vector2d result = Vector2d.sub(v, center);
		while(result.length() < 0.001) result.randomize();
		result.setLength(radius);
		result.add(center);
		return result;
	}
	
	public Vector2d closestPoint(Vector2d v, double offset){
		Vector2d result = Vector2d.sub(v, center);
		while(result.length() < 0.001) result.randomize();
		result.setLength(radius + offset);
		result.add(center);
		return result;
	}
}
