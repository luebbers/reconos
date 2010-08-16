package de.upb.reconos.layout.editor;

import java.awt.Cursor;
import java.awt.event.MouseEvent;

import javax.swing.event.ChangeListener;

import de.upb.reconos.gui.Interactable;
import de.upb.reconos.gui.Vector2d;
import de.upb.reconos.layout.BusMacro;
import de.upb.reconos.layout.Layout;
import de.upb.reconos.layout.Slot;

public class PRRInteractable implements Interactable {

	private Slot slot;
	private Layout layout;
	private ChangeListener changeListener;
	
	public PRRInteractable(Slot s, Layout l, ChangeListener cl){
		slot = s;
		layout = l;
		changeListener = cl;
	}
	
	public Slot getSlot(){
		return slot;
	}
	
	public boolean contains(double x, double y) {
		Range range = slot.getSliceRange();
		return x > range.getXMin() && x <= range.getXMax()
				&& y > range.getYMin() && y <= range.getYMax();
	}

	public void dragReleased(double x, double y) {
		dragTo(x,y);
	}

	public void dragTo(double x, double y) {
		Range range = slot.getSliceRange();
		int oldx = range.getXMin();
		int oldy = range.getYMin();
		
		int w = range.getWidth();
		int h = range.getHeight();
		range.setXMin((int)(x + 0.5));
		range.setYMin((int)(y + 0.5));
		range.setXMax(range.getXMin() + w - 1);
		range.setYMax(range.getYMin() + h - 1);
		
		int dx = range.getXMin() - oldx;
		int dy = range.getYMin() - oldy;
		
		for(BusMacro bm : slot.getBusMacros()){
			bm.setLocX(bm.getLocX() + dx);
			bm.setLocY(bm.getLocY() + dy);
		}
	}

	public Vector2d getPosition() {
		Range range = slot.getSliceRange();
		return new Vector2d(range.getXMin(), range.getYMin());
	}

	public boolean isDraggable() {
		return true;
	}

	public void onClick(MouseEvent e, double x, double y) {
		if(e.getButton() == 3){
			PRRMenu menu = new PRRMenu(layout,changeListener,slot);
			menu.show(e.getComponent(), e.getX(), e.getY());
		}
	}

	public Cursor getCursor() {
		return new Cursor(Cursor.MOVE_CURSOR);
	}
}
