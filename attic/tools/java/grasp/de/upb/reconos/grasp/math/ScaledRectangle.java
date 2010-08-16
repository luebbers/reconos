package de.upb.reconos.grasp.math;


import java.io.Serializable;

import de.upb.reconos.grasp.interfaces.Rectangle;


public class ScaledRectangle implements Rectangle, Serializable {

	private static final long serialVersionUID = 1L;
	public double mulWidth;
	public double mulHeight;
	public double addWidth;
	public double addHeight;
	public Rectangle rectangle;
	
	public ScaledRectangle(Rectangle r, double mulWidth, double mulHeight,
			double addWidth, double addHeight)
	{
		this.rectangle = r;
		this.mulWidth = mulWidth;
		this.mulHeight = mulHeight;
		this.addWidth = addWidth;
		this.addHeight = addHeight;
	}

	public boolean contains(double x, double y) {
		if(x < getCenterX() - getWidth()/2) return false;
		if(x > getCenterX() + getWidth()/2) return false;
		if(y < getCenterY() - getHeight()/2) return false;
		if(y > getCenterY() + getHeight()/2) return false;
		return true;
	}

	public double getHeight() {
		return rectangle.getHeight()*mulHeight + addHeight;
	}

	public double getWidth() {
		return rectangle.getWidth()*mulWidth + addWidth;
	}

	public double getLeft() {
		return getCenterX() - getWidth()/2;
	}

	public double getRight() {
		return getCenterX() + getWidth()/2;
	}

	public double getTop() {
		return getCenterY() - getHeight()/2;
	}
	
	public double getBottom() {
		return getCenterY() + getHeight()/2;
	}
	
	public double getCenterX(){
		return rectangle.getCenterX();
	}
	
	public double getCenterY(){
		return rectangle.getCenterY();
	}
}
