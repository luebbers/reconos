package de.upb.reconos.gui;

import java.awt.Cursor;
import java.awt.event.MouseEvent;


public interface Interactable {
	public boolean contains(double x, double y);
	public boolean isDraggable();
	public void dragTo(double x, double y);
	public void dragReleased(double x, double y);
	public void onClick(MouseEvent e, double x, double y);
	public Vector2d getPosition();
	public Cursor getCursor();
}
