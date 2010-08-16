package de.upb.reconos.grasp.interfaces;

import de.upb.reconos.grasp.math.Vector2d;


public interface Interactable {
	public boolean contains(double x, double y);
	public boolean isDraggable();
	public void dragTo(double x, double y);
	public void dragReleased(double x, double y);
	public void onClick(int button, double x, double y);
	public Vector2d getPosition();
}
