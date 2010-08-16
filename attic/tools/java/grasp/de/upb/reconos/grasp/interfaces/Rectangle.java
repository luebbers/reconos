package de.upb.reconos.grasp.interfaces;

public interface Rectangle {
	public double getLeft();
	public double getRight();
	public double getTop();
	public double getBottom();
	public double getWidth();
	public double getHeight();
	public double getCenterX();
	public double getCenterY();
	public boolean contains(double x, double y);
}
