package de.upb.reconos.layout.editor;

import java.awt.Cursor;
import java.awt.event.MouseEvent;

import de.upb.reconos.gui.Interactable;
import de.upb.reconos.gui.Vector2d;
import de.upb.reconos.layout.BusMacro;
import de.upb.reconos.layout.Slot;

public class BusMacroInteractable implements Interactable {

	public Slot slot;
	public int busMacroIndex;
	
	public BusMacroInteractable(Slot s, int idx){
		slot = s;
		busMacroIndex = idx;
	}
	
	public BusMacro getBusMacro(){
		return slot.getBusMacros().get(busMacroIndex);
	}
	
	private Range getRange(){
		return slot.getBusMacros().get(busMacroIndex).getRange();
	}
	
	public boolean contains(double x, double y) {
		Range range = getRange();
		return x >= range.getXMin() && x <= range.getXMax() + 1
				&& y >= range.getYMin() && y <= range.getYMax() + 1;
	}

	public void dragReleased(double x, double y) {
		dragTo(x,y);
	}

	public void dragTo(double x, double y) {
		slot.getBusMacros().get(busMacroIndex).setLoc((int)x, (int)y);	
	}

	public Vector2d getPosition() {
		Range range = getRange();
		return new Vector2d(range.getXMin(), range.getYMin());
	}

	public boolean isDraggable() {
		return true;
	}

	public void onClick(MouseEvent e, double x, double y) {
		if(e.getClickCount() == 2 && e.getButton() == 1){
			System.out.println("dclick on bm " + busMacroIndex);
			BusMacro bm = slot.getBusMacros().get(busMacroIndex);
			if(bm.getWidth() == BusMacro.NARROW){
				bm.setWidth(BusMacro.WIDE);
			}
			else {
				bm.setWidth(BusMacro.NARROW);
			}
		}
	}

	public Cursor getCursor() {
		return new Cursor(Cursor.MOVE_CURSOR);
	}
}
