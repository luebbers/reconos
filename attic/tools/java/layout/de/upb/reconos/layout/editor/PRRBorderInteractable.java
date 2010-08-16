package de.upb.reconos.layout.editor;

import java.awt.Cursor;
import java.awt.event.MouseEvent;

import de.upb.reconos.gui.Interactable;
import de.upb.reconos.gui.Vector2d;

public class PRRBorderInteractable implements Interactable {

	public static final int LEFT = 0;
	public static final int RIGHT = 1;
	public static final int TOP = 2;
	public static final int BOTTOM = 3;
	
	private Range range;
	private int side;
	
	public PRRBorderInteractable(Range r, int side){
		range = r;
		this.side = side;
	}
	
	public boolean contains(double x, double y) {
		if(side == LEFT){
			return x > range.getXMin() - 0.25 && x <= range.getXMin() + 0.25
					&& y > range.getYMin() && y <= range.getYMax();
		}
		if(side == RIGHT){
			return x > range.getXMax() + 1 - 0.25 && x <= range.getXMax() + 1 + 0.25
					&& y > range.getYMin() && y <= range.getYMax();
		}
		if(side == BOTTOM){
			return x > range.getXMin()  && x <= range.getXMax()
					&& y > range.getYMin()  - 0.25 && y <= range.getYMin() + 0.25;
		}
		if(side == TOP){
			return x > range.getXMin()  && x <= range.getXMax()
					&& y > range.getYMax() + 1 - 0.25 && y <= range.getYMax() + 1 + 0.25;
		}
		return false;
	}

	public void dragReleased(double x, double y) {
		dragTo(x,y);
	}

	public void dragTo(double x, double y) {
		if(side == LEFT){
			int left = (int)(x + 0.5);
			if (left >= range.getXMax()) left = range.getXMax() - 1;
			range.setXMin(left);
		}
		if(side == RIGHT){
			int right = (int)(x + 0.5);
			if (right <= range.getXMin()) right = range.getXMin() + 1;
			range.setXMax(right);
		}
		if(side == BOTTOM){
			int bottom = (int)(y + 0.5);
			if (bottom >= range.getYMax()) bottom = range.getYMax() - 1;
			range.setYMin(bottom);
		}
		if(side == TOP){
			int top = (int)(y + 0.5);
			if (top <= range.getYMin()) top = range.getYMin() + 1;
			range.setYMax(top);
		}
	}

	public Vector2d getPosition() {
		if(side == LEFT || side == BOTTOM){
			return new Vector2d(range.getXMin(), range.getYMin());
		}
		return new Vector2d(range.getXMax(), range.getYMax());
	}

	public boolean isDraggable() {
		return true;
	}

	public void onClick(MouseEvent e, double x, double y) {
		// nothing yet
	}

	public Cursor getCursor() {
		if(side == LEFT) return new Cursor(Cursor.W_RESIZE_CURSOR);
		if(side == RIGHT) return new Cursor(Cursor.E_RESIZE_CURSOR);
		if(side == BOTTOM) return new Cursor(Cursor.S_RESIZE_CURSOR);
		if(side == TOP) return new Cursor(Cursor.N_RESIZE_CURSOR);
		return null;
	}

}
