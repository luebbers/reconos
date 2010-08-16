package de.upb.reconos.grasp.math;


import java.io.Serializable;

import de.upb.reconos.grasp.interfaces.Rectangle;


public class CenterPointRectangle implements Rectangle, Serializable {

	private static final long serialVersionUID = 1L;
	private Vector2d center;
	private double width;
	private double height;
	
	public CenterPointRectangle(Vector2d center, double w, double h){
		this.center = center;
		setWidth(w);
		setHeight(h);
	}
	
	public CenterPointRectangle(double centerX, double centerY, double w, double h){
		this.center = new Vector2d(centerX, centerY);
		setWidth(w);
		setHeight(h);
	}
	
	public boolean contains(double x, double y){
		if(x < center.getX() - getWidth()/2) return false;
		if(x > center.getX() + getWidth()/2) return false;
		if(y < center.getY() - getHeight()/2) return false;
		if(y > center.getY() + getHeight()/2) return false;
		return true;
	}
	
	public double getLeft() { return center.getX() - getWidth()/2; }
	public double getRight() { return center.getX() + getWidth()/2; }
	public double getTop() { return center.getY() - getHeight()/2; }
	public double getBottom() { return center.getY() + getHeight()/2; }

	public void setHeight(double height) {
		this.height = height;
	}

	public double getHeight() {
		return height;
	}

	public void setWidth(double width) {
		this.width = width;
	}

	public double getWidth() {
		return width;
	}

	public void setCenter(Vector2d center) {
		this.center = center;
	}

	public Vector2d getCenter() {
		return center;
	}
	
	public double getCenterX(){
		return center.getX();
	}
	
	public double getCenterY(){
		return center.getY();
	}
}
